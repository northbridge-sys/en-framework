/*
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

string _enSNEP_RPCSend(
    string key_name,
    string target, // can be either a URL (for llHTTPRequest) or an http_request handle UUID (for llHTTPResponse)
    string target_prim,
    list http_parameters,
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
    #if defined TRACE_ENSNEP_SENDRPC
        enLog_TraceParams(
            "_enSNEP_RPCSend",
            [
                "key_name",
                "target",
                "target_prim",
                "http_parameters",
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
                enString_Elem(target),
                enPrim_Elem(target_prim),
                enList_Elem(http_parameters),
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

    if (enKey_IsNotNull(target))
    { // we are responding
        llHTTPResponse(
            target,
            200,
            _enRPC_Marshal(
                FLAG_ENRPC_EMBED_INT | FLAG_ENRPC_EMBED_PARAMS, // internal flags
                key_name,
                source_script,
                "", // target_region (not used for SNEP)
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
        return target;
    }
    
    // we are requesting
    return llHTTPRequest(
        target, 
        http_parameters, 
        _enRPC_Marshal(
            FLAG_ENRPC_EMBED_INT | FLAG_ENRPC_EMBED_PARAMS,
            key_name,
            llGetScriptName(),
            "", // target_region
            target_prim, // SNEP leaves target_prim blank for direct messages, or can include if target_url is an external relay service
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
}
