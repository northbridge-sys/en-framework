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
#define FLAG_ENRPC_PROTOCOL_LEP 0x1
#define FLAG_ENRPC_PROTOCOL_CLEP 0x2
#define FLAG_ENRPC_PROTOCOL_SNEP 0x4
#define FLAG_ENRPC_RETURN 0x8
#define FLAG_ENRPC_TYPE_REQUEST 0x10
#define FLAG_ENRPC_TYPE_RESPONSE 0x20
#define FLAG_ENRPC_TYPE_RESULT 0x40
#define FLAG_ENRPC_TYPE_ERROR 0x80

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

#define enCLEP_ResetSourceRegion() \
    enCLEP_StageSourceRegion("")

#define enCLEP_ResetSourcePrim() \
    enCLEP_StageSourcePrim("")

#define enCLEP_ListenRemove(domain) \
    enCLEP_Listen(domain, FLAG_ENRPC_LISTEN_REMOVE)

#define enCLEP_LEPRequest(target_link, target_script, domain, method, params, id) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_LEP, "", llGetScriptName(), "", (string)(target_link), target_script, domain, method, params, id, "", "")

#define enCLEP_LEPRequestSigned(key_name, target_link, target_script, domain, method, params, id) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_LEP, key_name, llGetScriptName(), "", (string)(target_link), target_script, domain, method, params, id, "", "")

#define enCLEP_LEPResult(target_link, target_script, domain, method, params, id, result) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_LEP, "", llGetScriptName(), "", (string)(target_link), target_script, domain, method, params, id, "0", result)

#define enCLEP_LEPResultSigned(key_name, target_link, target_script, domain, method, params, id, result) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_LEP, key_name, llGetScriptName(), "", (string)(target_link), target_script, domain, method, params, id, "0", result)

#define enCLEP_LEPError(target_link, target_script, domain, method, params, id, error_code, error_message) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_LEP, "", llGetScriptName(), "", (string)(target_link), target_script, domain, method, params, id, (string)(error_code), error_message)

#define enCLEP_LEPErrorSigned(key_name, target_link, target_script, domain, method, params, id, error_code, error_message) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_LEP, key_name, llGetScriptName(), "", (string)(target_link), target_script, domain, method, params, id, (string)(error_code), error_message)

#define enCLEP_CLEPRequest(target_region, target_prim, target_script, domain, method, params, id) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_CLEP, "", llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, "", "")

#define enCLEP_CLEPRequestSigned(key_name, target_region, target_prim, target_script, domain, method, params, id) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_CLEP, key_name, llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, "", "")

#define enCLEP_CLEPResult(target_region, target_prim, target_script, domain, method, params, id, result) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_CLEP, "", llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, "0", result)

#define enCLEP_CLEPResultSigned(key_name, target_region, target_prim, target_script, domain, method, params, id, result) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_CLEP, key_name, llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, "0", result)

#define enCLEP_CLEPError(target_region, target_prim, target_script, domain, method, params, id, error_code, error_message) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_CLEP, "", llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, (string)(error_code), error_message)

#define enCLEP_CLEPErrorSigned(key_name, target_region, target_prim, target_script, domain, method, params, id, error_code, error_message) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_CLEP, key_name, llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, (string)(error_code), error_message)

#define enCLEP_HybridRequest(target_region, target_prim, target_script, domain, method, params, id) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_LEP | FLAG_ENRPC_PROTOCOL_CLEP, "", llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, "", "")

#define enCLEP_HybridRequestSigned(key_name, target_region, target_prim, target_script, domain, method, params, id) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_LEP | FLAG_ENRPC_PROTOCOL_CLEP, key_name, llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, "", "")

#define enCLEP_HybridResult(target_region, target_prim, target_script, domain, method, params, id, result) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_LEP | FLAG_ENRPC_PROTOCOL_CLEP, "", llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, "0", result)

#define enCLEP_HybridResultSigned(key_name, target_region, target_prim, target_script, domain, method, params, id, result) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_LEP | FLAG_ENRPC_PROTOCOL_CLEP, key_name, llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, "0", result)

#define enCLEP_HybridError(target_region, target_prim, target_script, domain, method, params, id, error_code, error_message) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_LEP | FLAG_ENRPC_PROTOCOL_CLEP, "", llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, (string)(error_code), error_message)

#define enCLEP_HybridErrorSigned(key_name, target_region, target_prim, target_script, domain, method, params, id, error_code, error_message) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_LEP | FLAG_ENRPC_PROTOCOL_CLEP, key_name, llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, (string)(error_code), error_message)

#define enCLEP_SNEPRequest(target_url, target_prim, target_script, domain, method, params, id) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_SNEP, "", llGetScriptName(), target_url, target_prim, target_script, domain, method, params, id, "", "")

#define enCLEP_SNEPRequestSigned(key_name, target_url, target_prim, target_script, domain, method, params, id) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_SNEP, key_name, llGetScriptName(), target_url, target_prim, target_script, domain, method, params, id, "", "")

#define enCLEP_SNEPResult(target_request_id, target_prim, target_script, domain, method, params, id, result) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_SNEP, "", llGetScriptName(), target_request_id, target_prim, target_script, domain, method, params, id, "0", result)

#define enCLEP_SNEPResultSigned(key_name, target_request_id, target_prim, target_script, domain, method, params, id, result) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_SNEP, key_name, llGetScriptName(), target_request_id, target_prim, target_script, domain, method, params, id, "0", result)

#define enCLEP_SNEPError(target_request_id, target_prim, target_script, domain, method, params, id, error_code, error_message) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_SNEP, "", llGetScriptName(), target_request_id, target_prim, target_script, domain, method, params, id, (string)(error_code), error_message)

#define enCLEP_SNEPErrorSigned(key_name, target_request_id, target_prim, target_script, domain, method, params, id, error_code, error_message) \
    _enCLEP_Send(FLAG_ENRPC_PROTOCOL_SNEP, key_name, llGetScriptName(), target_request_id, target_prim, target_script, domain, method, params, id, (string)(error_code), error_message)

// note: target_prim may be target_link typecast to string for all enCLEP_Generate*() macros

#define enCLEP_GenerateRequest(target_region, target_prim, target_script, domain, method, params, id) \
    _enCLEP_Send(FLAG_ENRPC_RETURN, "", llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, "", "")

#define enCLEP_GenerateRequestSigned(key_name, target_region, target_prim, target_script, domain, method, params, id) \
    _enCLEP_Send(FLAG_ENRPC_RETURN, key_name, llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, "", "")

#define enCLEP_GenerateResult(target_region, target_prim, target_script, domain, method, params, id, result) \
    _enCLEP_Send(FLAG_ENRPC_RETURN, "", llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, "0", result)

#define enCLEP_GenerateResultSigned(key_name, target_region, target_prim, target_script, domain, method, params, id, result) \
    _enCLEP_Send(FLAG_ENRPC_RETURN, key_name, llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, "0", result)

#define enCLEP_GenerateError(target_region, target_prim, target_script, domain, method, params, id, error_code, error_message) \
    _enCLEP_Send(FLAG_ENRPC_RETURN, "", llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, (string)(error_code), error_message)

#define enCLEP_GenerateErrorSigned(key_name, target_region, target_prim, target_script, domain, method, params, id, error_code, error_message) \
    _enCLEP_Send(FLAG_ENRPC_RETURN, key_name, llGetScriptName(), target_region, target_prim, target_script, domain, method, params, id, (string)(error_code), error_message)

// NOTE: do not use FLAG_ENRPC_LISTEN_OWNERONLY across region borders!
#define FLAG_ENRPC_LISTEN_OWNERONLY 0x1
#define FLAG_ENRPC_LISTEN_REMOVE 0x80000000

#ifndef OVERRIDE_INTEGER_ENRPC_RESERVE_LISTENS
    #define OVERRIDE_INTEGER_ENRPC_RESERVE_LISTENS 0
#endif

/*
enCLEP_Channel is the hashing algorithm that converts a domain into a channel number for CLEP.
This is used to enforce channel separation on different domains. This reduces script time for llRegionSay calls.
CLEP channels are always negative, so we just set the 0x80000000 bit to force a negative integer of some kind.
This also naturally avoids PUBLIC_CHANNEL (0x0 -> 0x80000000) and DEBUG_CHANNEL (0x7FFFFFFF -> 0xFFFFFFFF).
*/
#define enCLEP_Channel(domain) \
    (llHash(domain) | CONST_INTEGER_NEGATIVE)

#define enCLEP_ReservedListens() \
    (!!_ENRPC_DIALOG_LSN + OVERRIDE_INTEGER_ENRPC_RESERVE_LISTENS)

/*
enCLEP_DialogChannel can be used to get the channel we are listing to if enCLEP_DialogListen was called.
*/
#define enCLEP_DialogChannel() \
    enCLEP_Channel((string)llGetInventoryKey(llGetScriptName()))
