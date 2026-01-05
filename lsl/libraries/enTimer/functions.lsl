/*
enTimer.lsl
Library Functions
En LSL Framework
Copyright (C) 2024  Northbridge Business Systems
https://docs.northbridgesys.com/en-framework

╒══════════════════════════════════════════════════════════════════════════════╕
│ LICENSE                                                                      │
└──────────────────────────────────────────────────────────────────────────────┘

This script is free software: you can redistribute it and/or modify it under the
terms of the GNU Lesser General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This script is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along
with this script.  If not, see <https://www.gnu.org/licenses/>.
*/

//  clears enTimer timers
enTimer_Reset()
{
    _ENTIMER_QUEUE = [];
    llSetTimerEvent(0.0);
}

//  adds an enTimer timer
string enTimer_Start(
    float interval,
    integer flags,
    string callback
)
{
    #if defined TRACE_ENTIMER
        enLog_TraceParams("enTimer_Start", [ "interval", "flags", "callback" ], [
            interval,
            flags,
            enString_Elem( callback )
            ]);
    #endif

    // check inputs
    if ( interval < 0.01 ) return NULL_KEY; // invalid interval
    if ( interval < OVERRIDE_FLOAT_ENTIMER_MINIMUM_INTERVAL ) interval = OVERRIDE_FLOAT_ENTIMER_MINIMUM_INTERVAL; // clamp to minimum interval
    string id = llGenerateKey();
    #if defined FEATURE_ENTIMER_DISABLE_MULTIPLE
        // multiple timers not enabled, so just overwrite queue
        _ENTIMER_QUEUE = [
            id,
            callback,
            (integer)( interval * 1000 ) * (flags & FLAG_ENTIMER_PERIODIC)
        ];

        // start single timer
        llSetTimerEvent( interval );
    #else
        // multiple timers enabled, so we need to do a little more

        // check if the callback already exists in the queue
        integer existing_index = llListFindList(llList2ListSlice(_ENTIMER_QUEUE, 0, -1, _ENTIMER_QUEUE_STRIDE, 1), [callback]);
        if (existing_index != -1)
        { // this callback already exists, so delete in preparating for re-adding the timer
            // grab existing id
            id = llList2String(_ENTIMER_QUEUE, existing_index * _ENTIMER_QUEUE_STRIDE);

            // delete existing timer
            _ENTIMER_QUEUE = llDeleteSubList(_ENTIMER_QUEUE, existing_index * _ENTIMER_QUEUE_STRIDE, (existing_index + 1) * _ENTIMER_QUEUE_STRIDE - 1);
        }

        // add to queue
        _ENTIMER_QUEUE += [
            id,
            callback,
            (integer)( interval * 1000 ) * (flags & FLAG_ENTIMER_PERIODIC),
            enDatetime_AddMillisec( enDatetime_NowToMillisec(), (integer)( interval * 1000 ) ) // convert to ms
        ];

        // reprocess queue
        _entimer_timer();
    #endif
    return id;
}

//  removes an enTimer timer
integer enTimer_Cancel(
    string id // required unless FEATURE_ENTIMER_DISABLE_MULTIPLE is set - use enTimer_Find if not known
    )
{
    #if defined TRACE_ENTIMER
        enLog_TraceParams("enTimer_Cancel", [ "id" ], [
            enString_Elem( id )
            ]);
    #endif
    #if defined FEATURE_ENTIMER_DISABLE_MULTIPLE
        _ENTIMER_QUEUE = []; // we only have one timer, so cancel it
        llSetTimerEvent( 0.0 );
    #else
        // find timer by id
        integer i = llListFindList( llList2ListSlice( _ENTIMER_QUEUE, 0, -1, _ENTIMER_QUEUE_STRIDE, 0 ), [ id ] );
        if ( i == -1 ) return 0; // not found
        // found, delete it
        _ENTIMER_QUEUE = llDeleteSubList( _ENTIMER_QUEUE, i, i + _ENTIMER_QUEUE_STRIDE - 1 );
        _entimer_timer(); // then reprocess queue
    #endif
    return 1;
}

//  finds a timer by callback
string enTimer_Find(
    string callback
    )
{
    #if defined TRACE_ENTIMER
        enLog_TraceParams("enTimer_Find", [ "callback" ], [
            enString_Elem( callback )
            ]);
    #endif
    integer i = llListFindList( llList2ListSlice( _ENTIMER_QUEUE, 0, -1, _ENTIMER_QUEUE_STRIDE, 1 ), [ callback ] );
    if ( i == -1 ) return "";
    return llList2String( _ENTIMER_QUEUE, i * _ENTIMER_QUEUE_STRIDE );
}

//  internal function to check enTimer queue to see if any timers are due to be triggered
_entimer_timer()
{
    #if defined FEATURE_ENTIMER_ENABLE_PREEMPTION
        if (_ENTIMER_PREEMPT) return; // check preemption here, return early if preempted
    #endif
    #if defined TRACE_ENTIMER
        enLog_TraceParams("_entimer_timer", [], []);
    #endif
    llSetTimerEvent(0.0);
    if ( _ENTIMER_QUEUE == [] ) return; // no timer to check
    #if defined FEATURE_ENTIMER_DISABLE_MULTIPLE
        entimer_timer(
            llList2String( _ENTIMER_QUEUE, 0 ), // id
            llList2String( _ENTIMER_QUEUE, 1 ), // callback
            ((integer)llList2String( _ENTIMER_QUEUE, 2 ) * (integer)llList2String( _ENTIMER_QUEUE, 3 )) * 0.001 // length * periodic
        );
        if ( (integer)llList2String( _ENTIMER_QUEUE, 3 ) ) llSetTimerEvent( (integer)llList2String( _ENTIMER_QUEUE, 2 ) * 0.001 ); // periodic
        else _ENTIMER_QUEUE = []; // one-shot
    #else
        integer now = enDatetime_NowToMillisec();
        integer i;
        integer l = llGetListLength( _ENTIMER_QUEUE ) / _ENTIMER_QUEUE_STRIDE;
        integer lowest = 0x7FFFFFFF;
        list triggers;
        for (i = 0; i < l; i++)
        {
            string t_id = llList2String( _ENTIMER_QUEUE, i * _ENTIMER_QUEUE_STRIDE );
            string t_callback = llList2String( _ENTIMER_QUEUE, i * _ENTIMER_QUEUE_STRIDE + 1 );
            integer t_length = (integer)llList2String( _ENTIMER_QUEUE, i * _ENTIMER_QUEUE_STRIDE + 2 );
            integer t_trigger = (integer)llList2String( _ENTIMER_QUEUE, i * _ENTIMER_QUEUE_STRIDE + 3 );
            integer remain = enDatetime_AddMillisec( t_trigger, -now );
            if ( remain * 0.001 < OVERRIDE_FLOAT_ENTIMER_MINIMUM_INTERVAL )
            { // timer triggered
                if ( !t_length )
                { // one-shot, so drop it from the queue
                    _ENTIMER_QUEUE = llDeleteSubList( _ENTIMER_QUEUE, i * _ENTIMER_QUEUE_STRIDE, ( i + 1 ) * _ENTIMER_QUEUE_STRIDE - 1 );
                    i--; l--; // shift for loop to account for lost queue stride
                }
                else if ( t_length < lowest ) lowest = t_length; // periodic, and it is currently the next timer to trigger

                // internal loopbacks
                if (t_callback == "enPrim_TextClear") enPrim_TextClear();
                else
                {
                    #if defined EVENT_ENTIMER_TIMER
                        triggers += [t_id, t_callback, t_length, t_trigger];
                    #endif
                }
            }
            else if ( remain < lowest ) lowest = remain; // timer not triggered, but it is currently the next timer to trigger
        }
        if ( lowest != 0x7FFFFFFF )
        { // a timer is still in the queue
            llSetTimerEvent( lowest * 0.001 );
            #if defined TRACE_ENTIMER
                enLog_Trace("enTimer llSetTimerEvent(" + (string)(lowest * 0.001) + ")");
            #endif
        }
        /*
        entimer_timer calls need to be made AFTER the next timer is scheduled, because otherwise there is an ordering problem
        if code that runs in entimer_timer re-calls enTimer_Start, it will modify the enTimer queue and schedule the next timer
        but if this function then sets the timer to the OLD timer, it causes the old lowest timer to be used instead of the new one
        moving these triggers out to be enumerated separately solves this problem - calls to enTimer_Start will correctly reschedule the timer
        */
        l = llGetListLength(triggers) / 4;
        for (i = 0; i < l; i++)
        {
            entimer_timer( // fire function
                llList2String(triggers, i * 4), // timer id
                llList2String(triggers, i * 4 + 1), // callback
                ((integer)llList2String(triggers, i * 4 + 2) * (integer)llList2String(triggers, i * 4 + 3)) * 0.001 // length * periodic
            );
        }
    #endif
}

#if defined FEATURE_ENTIMER_ENABLE_PREEMPTION
/* 
Note that this needs to be set BEFORE setting the timer with llSetTimerEvent,
since the timer will be reset when calling enTimer_SetPreempt(1)
*/
    enTimer_SetPreempt(
        integer i
    )
    {
        #if defined TRACE_ENTIMER
            enLog_TraceParams(
                "enTimer_SetPreempt",
                [
                    "i"
                ],
                [
                    i
                ]
            );
        #endif
        _ENTIMER_PREEMPT = !!i;
        _entimer_timer(); // check immediately in case no longer preempting - cheaper memory-wise to call and let it return early
        if (_ENTIMER_PREEMPT) llSetTimerEvent(0.0); // now preempting, so stop timer immediately
    }
#endif
