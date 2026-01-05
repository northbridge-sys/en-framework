/*
En LSL Framework
Copyright (C) 2024-25  Northbridge Business Systems
https://docs.northbridgesys.com/en-framework

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

// EVENT HOOK DEFINITIONS

// en_link_message
#if defined EVENT_EN_LINK_MESSAGE
    #define _EVENT_LINK_MESSAGE
    #define _HOOK_EN_LINK_MESSAGE
#endif

// _enLEP_link_message
#if defined EVENT_ENLEP_RPC_REQUEST || defined EVENT_ENLEP_RPC_RESULT || defined EVENT_ENLEP_RPC_ERROR
    #define _EVENT_LINK_MESSAGE
    #define _HOOK_ENLEP_LINK_MESSAGE
#endif

// EVENT HANDLER

#if defined _EVENT_LINK_MESSAGE
    link_message(integer l, integer i, string s, key k)
    {
#endif

        // trace event
        
        #if defined _EVENT_LINK_MESSAGE && defined TRACE_EVENT_LINK_MESSAGE
            enLog_TraceParams(
                "link_message",
                [
                    "l",
                    "i",
                    "s",
                    "k"
                ], [
                    l,
                    i,
                    enString_Elem(s),
                    enString_Elem((string)k)
                ]
            );
        #endif

        // process through hooks until one catches

        integer e;

        #if defined _HOOK_ENLEP_LINK_MESSAGE
            e = _enLEP_link_message(l, i, s, k);
            // if positive, valid LEP message, but not necessarily processed
            if (~e & CONST_INTEGER_NEGATIVE)
        #endif
        #if defined _HOOK_ENLEP_LINK_MESSAGE && !defined TRACE_EVENT_LINK_MESSAGE
            return; // just return
        #endif

        #if defined _HOOK_ENLEP_LINK_MESSAGE && defined TRACE_EVENT_LINK_MESSAGE
            { // print trace output and return
                enLog_Trace("enLEP accepted link_message: " + (string)e);
                return;
            }
            else enLog_Trace("enLEP rejected link_message: " + (string)e);
        #endif

		#if defined _HOOK_EN_LINK_MESSAGE
			en_link_message(l, i, s, k);
		#endif

#if defined _EVENT_LINK_MESSAGE
	}
#endif
