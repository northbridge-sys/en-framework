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

// if we want to receive any CLEP messages, trigger _enRPC_listen()
#if (defined FEATURE_ENRPC_PROTOCOL_CLEP || defined FEATURE_ENRPC_PROTOCOL_CLEP_INBOUND)
    #define _EVENT_LISTEN
    #define _HOOK_ENRPC_LISTEN
#endif

// if we defined EVENT_EN_LISTEN, pass all non-caught listen() events to en_listen()
#if defined EVENT_EN_LISTEN
    #define _EVENT_LISTEN
    #define _HOOK_EN_LISTEN
#endif

// if we are using listen() and want to trace it, define the trace hook
#if defined _EVENT_LISTEN && defined TRACE_EVENT_LISTEN
    #define _TRACE_EVENT_LISTEN
#endif

#if defined _EVENT_LISTEN
	listen(
        integer channel,
        string name,
        key id,
        string message
    )
	{
#endif

        #if defined _TRACE_EVENT_LISTEN
            enLog_TraceParams(
                "listen",
                [
                    "channel",
                    "name",
                    "id",
                    "message"
                ],
                [
                    channel,
                    enString_Elem(name),
                    enPrim_Elem(id),
                    enString_Elem(message)
                ]
            );
        #endif

        #if defined _HOOK_ENRPC_LISTEN
		    if (~_enRPC_listen(channel, name, id, message) & CONST_INTEGER_NEGATIVE) return; // positive/zero = caught, negative = rejected
        #endif
        
		#if defined _HOOK_EN_LISTEN
			en_listen(channel, name, id, message);
		#endif

#if defined _EVENT_LISTEN
	}
#endif
