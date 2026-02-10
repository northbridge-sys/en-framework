/*
En LSL Framework
Copyright (C) 2024-26  Northbridge Business Systems
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

// if we want to receive SNEP requests, trigger _enRPC_http_request()
#if defined FEATURE_ENRPC_PROTOCOL_SNEP || defined FEATURE_ENRPC_PROTOCOL_SNEP_REQUEST
    #define _EVENT_HTTP_REQUEST
    #define _HOOK_ENRPC_HTTP_REQUEST
#endif

// if we want to, pass all non-caught events
#if defined EVENT_EN_HTTP_REQUEST
    #define _EVENT_HTTP_REQUEST
    #define _HOOK_EN_HTTP_REQUEST
#endif

// if we are using this event and want to trace it, define the trace hook
#if defined _EVENT_HTTP_REQUEST && defined TRACE_EVENT_HTTP_REQUEST
    #define _TRACE_EVENT_HTTP_REQUEST
#endif



#if defined _EVENT_HTTP_REQUEST
	http_response(
        key request,
        integer status,
        list metadata,
        string body
    )
	{
#endif

        // log event if requested
        #if defined _TRACE_EVENT_HTTP_REQUEST
            enLog_TraceParams(
                "http_request",
                [
                    "request",
                    "method",
                    "body"
                ],
                [
                    enString_Elem(request),
                    enString_Elem(method),
                    enString_Elem(body)
                ]
            );
        #endif

        #if defined _HOOK_ENRPC_HTTP_REQUEST
		    if (~_enRPC_http_request(request, method, body) & CONST_INTEGER_NEGATIVE) return; // positive/zero = caught, negative = rejected
        #endif
        
		#if defined _HOOK_EN_HTTP_REQUEST
            en_http_request( request, method, body );
		#endif

#if defined _EVENT_HTTP_REQUEST
	}
#endif
