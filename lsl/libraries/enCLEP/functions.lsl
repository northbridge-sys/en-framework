/*
enCLEP.lsl
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

/*
enCLEP_DialogListen opens a regular llListen on an enCLEP channel tied to this prim UUID and script name.
This can be used in conjunction with enCLEP_DialogChannel for a safe nearly-guaranteed-random channel for this script.
*/
enCLEP_DialogListen()
{
    _enCLEP_UnListenDomains();
    if (_ENCLEP_DIALOG_LSN) llListenRemove(_ENCLEP_DIALOG_LSN);
    integer channel = enCLEP_DialogChannel();
    _ENCLEP_DIALOG_LSN = llListen(channel, "", "", "");
    enLog_Trace("Dialog listening on channel " + (string)channel + " handle " + (string)_ENCLEP_DIALOG_LSN);
    _enCLEP_ListenDomains();
}

/*
Removes the listen created by enCLEP_DialogListen.
*/
enCLEP_DialogListenRemove()
{
    if (!_ENCLEP_DIALOG_LSN) return;
    _enCLEP_UnListenDomains();
    llListenRemove(_ENCLEP_DIALOG_LSN);
    _ENCLEP_DIALOG_LSN = 0;
    _enCLEP_ListenDomains();
}

/*
Initializes or updates a dynamically managed enCLEP listener.
This is like llListen, but easier to use.

enCLEP_Listen(...) will return 0 and fail to add the listen if you attempt to
add more than 65 listeners (the maximum allowed per script). If you call
llListen separately, set the number of listens you want reserved for non-enCLEP\
use by adding the following line:
    #define OVERRIDE_INTEGER_ENCLEP_RESERVE_LISTENS x
where x is the number of listens you want to allocate for non-enCLEP use.

Note: domains can be set as the local prim's UUID, in which case they will be
automatically refreshed on key or link change. However, this ONLY works if the
domain itself is just the UUID - no other data can be added.

WARNING: If the local prim's UUID is used as the domain, you MUST use the
state_entry, on_rez, and changed event handler include files, which will
dynamically update the domain after a key change. (This is done automatically
in event-handlers.lsl if you use it.)
*/
integer enCLEP_Listen(
    string domain,  // domain to listen to
    integer flags   // ENCLEP_LISTEN_* flags
)
{
    #if defined TRACE_ENCLEP
        enLog_TraceParams("enCLEP_Listen", ["domain", "flags"], [
            enString_Elem(domain),
            enInteger_ElemBitfield(flags)
            ]);
    #endif
    _enCLEP_UnListenDomains();
    integer index = llListFindList(_ENCLEP_DOMAINS, [domain]);
    if (index == -1 && flags & FLAG_ENCLEP_LISTEN_REMOVE)
    { // nothing to remove, so return error
        _enCLEP_ListenDomains();
        return __LINE__;
    }
    if (~index) _ENCLEP_DOMAINS = llDeleteSubList(_ENCLEP_DOMAINS, index, index + _ENCLEP_DOMAINS_STRIDE - 1); // index == -1; delete existing domain enCLEP, so it can be cleanly appended to the end
    if (llGetListLength(_ENCLEP_DOMAINS) / _ENCLEP_DOMAINS_STRIDE + OVERRIDE_INTEGER_ENCLEP_RESERVE_LISTENS > 63)
    { // too many listens (maximum 65, so if we are currently at 64 or more, fail)
        _enCLEP_ListenDomains();
        return __LINE__;
    }
    if (~flags & FLAG_ENCLEP_LISTEN_REMOVE) _ENCLEP_DOMAINS += [domain, flags, 0]; // add to _ENCLEP_DOMAINS only if we aren't removing it
    _enCLEP_ListenDomains();
    return 0;
}

//  resets and removes all enCLEP listeners, for single-purpose scripts to not have to independently keep track of listen handles
enCLEP_Reset()
{
    #if defined TRACE_ENCLEP
        enLog_TraceParams("enCLEP_Reset", [], []);
    #endif
    _enCLEP_UnListenDomains();
    _ENCLEP_DOMAINS = [];
}

//  Internal function that dynamically selects a chat method to use based on the target prim
//  NULL_KEY or "" can be passed as a prim to use llRegionSay automatically
//  If FEATURE_ENCLEP_ENABLE_SHOUT is defined, a llRegionSayTo message will be sent via llShout to attempt to reach a prim across a nearby sim border
_enCLEP_SendRaw( // llRegionSayTo with llRegionSay for NULL_KEY instead of silently failing
    string target_prim,
    integer channel,
    string message
    )
{
    #if defined TRACE_ENCLEP_SENDRAW
        enLog_TraceParams("_enCLEP_SendRaw", ["target_prim", "channel", "message"], [
            enString_Elem(target_prim),
            channel,
            enString_Elem(message)
        ]);
    #endif
        if (target_prim == "") target_prim = NULL_KEY;
        if (target_prim == NULL_KEY) llRegionSay(channel, message); // RS if prim is not specified
        else if (llGetObjectDetails(target_prim, [OBJECT_PHANTOM]) != []) llRegionSayTo(target_prim, channel, message); // RST if prim is in region
    #if defined FEATURE_ENCLEP_ENABLE_SHOUT
        else llShout(channel, message); // shout if prim is not in region and FEATURE_ENCLEP_ENABLE_SHOUT is defined
    #elif defined FEATURE_ENCLEP_ENABLE_SAY
        else llSay(channel, message); // say if prim is not in region and FEATURE_ENCLEP_ENABLE_SAY is defined
    #elif defined FEATURE_ENCLEP_ENABLE_WHISPER
        else llWhisper(channel, message); // whisper if prim is not in region and FEATURE_ENCLEP_ENABLE_WHISPER is defined
    #endif
}

/*
CLEP-RPC, compatible with LEP-RPC.
*/
string _enCLEP_RPCSend(
    string key_name,
    string target_region,
    string target_prim,
    string target_script,
    string domain,
    integer int,
    string method,
    string params,
    string id,
    string result,
    integer error_code,
    string error_message,
    string error_data
)
{
    #if defined TRACE_ENCLEP_SENDRPC
        enLog_TraceParams(
            "_enCLEP_RPCSend",
            [
                "key_name",
                "target_region",
                "target_prim",
                "target_script",
                "domain",
                "int",
                "method",
                "params",
                "id",
                "result",
                "error_code",
                "error_message",
                "error_data"
            ],
            [
                enString_Elem(key_name),
                enString_Elem(target_region),
                enPrim_Elem(target_prim),
                enString_Elem(target_script),
                enString_Elem(domain),
                int,
                method,
                params,
                id,
                result,
                error_code,
                enString_Elem(error_message),
                error_data
            ]
        );
    #endif

    _enCLEP_SendRaw(
        target_prim,
        enCLEP_Channel(domain),
        _enRPC_Marshal(
            FLAG_ENRPC_EMBED_INT | FLAG_ENRPC_EMBED_PARAMS,
            key_name,
            llGetScriptName(),
            target_region,
            target_prim,
            target_script,
            domain,
            int,
            method,
            params,
            id,
            result,
            error_code,
            error_message,
            error_data
        )
    );

    return id;
}

/*
Process incoming listen event to see if it is a CLEP message.
If not, return a positive integer.
If so, check that the message is acceptable (matches a listened-to domain, ownership checks, etc.)
If the message is acceptable, route it appropriately (either to enLEP, or whatever other library or protocol) and return 0.
If not, return 0 to signal a CLEP message even if it wasn't routable.
*/

integer _enCLEP_listen(
    integer channel,
    string source_name,
    string source_prim,
    string s
)
{
    integer e = _enRPC_Unmarshal(
        source_prim, // source_prim
        -1, // source_link
        s, // json
        0, // int (used only if not in json)
        "" // params (used only if not in json)
    );
    
    #if defined TRACE_ENCLEP_LISTEN
        enLog_TraceParamsResult(
            "_enCLEP_listen",
            [
                "channel",
                "source_name",
                "source_prim",
                "s"
            ], [
                channel,
                enString_Elem(source_name),
                enString_Elem(source_prim),
                enString_Elem(s)
            ],
            (string)e
        );
    #endif

    return e;
}

//  internal function that runs llListenRemove on everything in _ENCLEP_DOMAINS
_enCLEP_UnListenDomains()
{
    #if defined TRACE_ENCLEP
        enLog_TraceParams("enCLEP_UnListenDomains", [], []);
    #endif
    integer i;
    integer l = llGetListLength(_ENCLEP_DOMAINS) / _ENCLEP_DOMAINS_STRIDE;
    for (i = 0; i < l; i++) llListenRemove((integer)llList2String(_ENCLEP_DOMAINS, i * _ENCLEP_DOMAINS_STRIDE + 2)); // for each domain in _ENCLEP_DOMAINS, remove listen by handle (we'll be replacing later)
}

//  internal function that runs llListen on everything in _ENCLEP_DOMAINS - DON'T run this without running _enCLEP_UnListenDomains() first!
_enCLEP_ListenDomains()
{
    #if defined TRACE_ENCLEP
        enLog_TraceParams("enCLEP_ListenDomains", [], []);
    #endif

    integer i;
    integer l = llGetListLength(_ENCLEP_DOMAINS) / _ENCLEP_DOMAINS_STRIDE;
    if (l > 64 - enCLEP_Reserved())
    {
        enLog_Warn("enCLEP overflow (" + (string)l + " + " + (string)enCLEP_Reserved() + " reserved > 64)");
        l = 64 - enCLEP_Reserved();
    }
    list c;
    // for each domain in _ENCLEP_DOMAINS, add listen and update _ENCLEP_DOMAINS with handle
    for (i = 0; i < l; i++)
    {
        string domain = llList2String(_ENCLEP_DOMAINS, i * _ENCLEP_DOMAINS_STRIDE);
        integer channel = enCLEP_Channel(domain);
        c += [channel];
        integer handle = llListen(llList2Integer(c, -1), "", "", "");
        llListReplaceList(_ENCLEP_DOMAINS, [handle], i * _ENCLEP_DOMAINS_STRIDE + 2, i * _ENCLEP_DOMAINS_STRIDE + 2);
        enLog_Trace("enCLEP listening on domain \"" + domain + "\" channel " + (string)channel + " handle " + (string)handle);
    }
}

//  internal function that runs after key change to reset any listens based on previous UUID
_enCLEP_uuid_changed(
    string last_uuid
)
{
    _enCLEP_UnListenDomains();
    // are we listening to a self-domain?
    integer index = llListFindList(llList2ListSlice(_ENCLEP_DOMAINS, 0, -1, _ENCLEP_DOMAINS_STRIDE, 0), [last_uuid]);
    // if we are, replace it
    if (index != -1) _ENCLEP_DOMAINS = llListReplaceList(_ENCLEP_DOMAINS,
        [(string)llGetKey()],
        index * _ENCLEP_DOMAINS_STRIDE,
        index * _ENCLEP_DOMAINS_STRIDE);
    _enCLEP_ListenDomains();
}
