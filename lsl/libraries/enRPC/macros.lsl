/*
En LSL Framework
Copyright (C) 2024-25  Northbridge Business Systems
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

#define CONST_ENRPC_DATA_TIMESTAMP 0
#define CONST_ENRPC_DATA_SOURCE_REGION 1
#define CONST_ENRPC_DATA_SOURCE_PRIM 2
#define CONST_ENRPC_DATA_SOURCE_SCRIPT 3
#define CONST_ENRPC_DATA_TARGET_SELECTOR 4
#define CONST_ENRPC_DATA_TARGET_PRIM 5
#define CONST_ENRPC_DATA_TARGET_SCRIPT 6
#define CONST_ENRPC_DATA_DOMAIN 7
#define CONST_ENRPC_DATA_METHOD 8
#define CONST_ENRPC_DATA_PARAMS 9
#define CONST_ENRPC_DATA_ID 10
#define CONST_ENRPC_DATA_E 11
#define CONST_ENRPC_DATA_RESULT 12
#define CONST_ENRPC_DATA_SIGNATURE_METHOD 13
#define CONST_ENRPC_DATA_SIGNATURE_ALGORITHM 14
#define CONST_ENRPC_DATA_SIGNATURE_HASH 15

// internal flags
#define FLAG_ENRPC_METHOD_LEP 0x1
#define FLAG_ENRPC_METHOD_CLEP 0x2
#define FLAG_ENRPC_METHOD_SNEP 0x4
#define FLAG_ENRPC_REQUEST 0x10
#define FLAG_ENRPC_RESULT 0x20
#define FLAG_ENRPC_ERROR 0x40

#if !defined OVERRIDE_INTEGER_ENRPC_LINK_MESSAGE_SCOPE
    #define OVERRIDE_INTEGER_ENRPC_LINK_MESSAGE_SCOPE LINK_THIS
#endif

#if !defined OVERRIDE_STRING_ENRPC_LEP_DOMAIN
    #define OVERRIDE_STRING_ENRPC_LEP_DOMAIN ""
#endif

#if !defined OVERRIDE_STRING_ENRPC_HMAC_ALGORITHM
    #define OVERRIDE_STRING_ENRPC_HMAC_ALGORITHM "sha256"
#endif

#if !defined OVERRIDE_STRING_ENRPC_RSA_ALGORITHM
    #define OVERRIDE_STRING_ENRPC_RSA_ALGORITHM "sha512"
#endif

#if !defined OVERRIDE_INTEGER_ENRPC_SIGNATURE_EXPIRY
    #define OVERRIDE_INTEGER_ENRPC_SIGNATURE_EXPIRY 3
#endif

#if defined FEATURE_ENRPC_ENABLE_SNEP
    list _ENRPC_HTTP_PARAMETERS;
#endif

#define enRPC_ListenRemove(domain) \
    enRPC_Listen(domain, FLAG_ENRPC_LISTEN_REMOVE)

#define enRPC_LEPRequest(target_link, target_script, domain, method, params, id) \
    _enRPC_Send(FLAG_ENRPC_METHOD_LEP, "", llGetScriptName(), "", (string)(target_link), target_script, domain, method, params, id, "", "")

#define enRPC_LEPRequestSigned(key_name, target_link, target_script, domain, method, params, id) \
    _enRPC_Send(FLAG_ENRPC_METHOD_LEP, key_name, llGetScriptName(), "", (string)(target_link), target_script, domain, method, params, id, "", "")

#define enRPC_LEPResult(target_link, target_script, domain, method, params, id, result) \
    _enRPC_Send(FLAG_ENRPC_METHOD_LEP, "", llGetScriptName(), "", (string)(target_link), target_script, domain, method, params, id, "0", result)

#define enRPC_LEPResultSigned(key_name, target_link, target_script, domain, method, params, id, result) \
    _enRPC_Send(FLAG_ENRPC_METHOD_LEP, key_name, llGetScriptName(), "", (string)(target_link), target_script, domain, method, params, id, "0", result)

#define enRPC_LEPError(target_link, target_script, domain, method, params, id, error_code, error_message) \
    _enRPC_Send(FLAG_ENRPC_METHOD_LEP, "", llGetScriptName(), "", (string)(target_link), target_script, domain, method, params, id, (string)(error_code), error_message)

#define enRPC_LEPErrorSigned(key_name, target_link, target_script, domain, method, params, id, error_code, error_message) \
    _enRPC_Send(FLAG_ENRPC_METHOD_LEP, key_name, llGetScriptName(), "", (string)(target_link), target_script, domain, method, params, id, (string)(error_code), error_message)

#define enRPC_CLEPRequest(target_region, target_prim, target_script, domain, method, params, id) \
    _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, "", llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, "", "")

#define enRPC_CLEPRequestSigned(key_name, target_region, target_prim, target_script, domain, method, params, id) \
    _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, key_name, llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, "", "")

#define enRPC_CLEPResult(target_region, target_prim, target_script, domain, method, params, id, result) \
    _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, "", llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, "0", result)

#define enRPC_CLEPResultSigned(key_name, target_region, target_prim, target_script, domain, method, params, id, result) \
    _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, key_name, llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, "0", result)

#define enRPC_CLEPError(target_region, target_prim, target_script, domain, method, params, id, error_code, error_message) \
    _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, "", llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, (string)(error_code), error_message)

#define enRPC_CLEPErrorSigned(key_name, target_region, target_prim, target_script, domain, method, params, id, error_code, error_message) \
    _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, key_name, llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, (string)(error_code), error_message)

#define enRPC_SNEPRequest(target_url, target_prim, target_script, domain, method, params, id) \
    _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, "", llGetScriptName(), target_url, target_prim, target_script, domain, method, params, id, "", "")

#define enRPC_SNEPRequestSigned(key_name, target_url, target_prim, target_script, domain, method, params, id) \
    _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, key_name, llGetScriptName(), target_url, target_prim, target_script, domain, method, params, id, "", "")

#define enRPC_SNEPResult(target_request_id, target_prim, target_script, domain, method, params, id, result) \
    _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, "", llGetScriptName(), target_request_id, target_prim, target_script, domain, method, params, id, "0", result)

#define enRPC_SNEPResultSigned(key_name, target_request_id, target_prim, target_script, domain, method, params, id, result) \
    _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, key_name, llGetScriptName(), target_request_id, target_prim, target_script, domain, method, params, id, "0", result)

#define enRPC_SNEPError(target_request_id, target_prim, target_script, domain, method, params, id, error_code, error_message) \
    _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, "", llGetScriptName(), target_request_id, target_prim, target_script, domain, method, params, id, (string)(error_code), error_message)

#define enRPC_SNEPErrorSigned(key_name, target_request_id, target_prim, target_script, domain, method, params, id, error_code, error_message) \
    _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, key_name, llGetScriptName(), target_request_id, target_prim, target_script, domain, method, params, id, (string)(error_code), error_message)
