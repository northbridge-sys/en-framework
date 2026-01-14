/*
enCLEP.lsl
Library Macros
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

// NOTE: do not use FLAG_ENRPC_LISTEN_OWNERONLY across region borders!
#define FLAG_ENRPC_LISTEN_OWNERONLY 0x1
#define FLAG_ENRPC_LISTEN_REMOVE 0x80000000

#ifndef OVERRIDE_INTEGER_ENRPC_RESERVE_LISTENS
    #define OVERRIDE_INTEGER_ENRPC_RESERVE_LISTENS 0
#endif

// used by enRPC_DialogListen()
integer _ENRPC_DIALOG_LSN;

list _ENRPC_CLEP; // domain, flags, handle
#define _ENRPC_CLEP_STRIDE 3

/*
enRPC_Channel is the hashing algorithm that converts a domain into a channel number for CLEP.
This is used to enforce channel separation on different domains. This reduces script time for llRegionSay calls.
CLEP channels are always negative, so we just set the 0x80000000 bit to force a negative integer of some kind.
This also naturally avoids PUBLIC_CHANNEL (0x0 -> 0x80000000) and DEBUG_CHANNEL (0x7FFFFFFF -> 0xFFFFFFFF).
*/
#define enRPC_Channel(domain) \
    (llHash(domain) | CONST_INTEGER_NEGATIVE)

#define enRPC_ReservedListens() \
    (!!_ENRPC_DIALOG_LSN + OVERRIDE_INTEGER_ENRPC_RESERVE_LISTENS)

/*
enRPC_DialogChannel can be used to get the channel we are listing to if enRPC_DialogListen was called.
*/
#define enRPC_DialogChannel() \
    enRPC_Channel((string)llGetInventoryKey(llGetScriptName()))

/*!
Sends a request using the CLEP-RPC protocol.
@param string target_prim Target prim UUID ("" for all prims in region).
@param string target_script Target script name ("" for all in targeted link(s)).
@param string clep_domain CLEP domain to send message over.
@param integer int Any integer.
@param string method Any method. Typically separated by periods ("."), e.g.: system.display.pixel.color
@param string params Any JSON. This parameter is passed as a raw string, but needs to be valid JSON for CLEP encapsulation, which assumes it is valid JSON.
@param string id Any string. If "", will be omitted.
*/
#define enCLEP_RPCRequest(                                                   target_prim, target_script, domain, int, method, params, id) \
              _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, "", llGetScriptName(), "", target_prim, target_script, domain, int, method, params, id, "", 0, "", "")

#define enCLEP_RequestRoutedRPC(                                               target_region, target_prim, target_script, domain, int, method, params, id) \
                    _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, "", llGetScriptName(), target_region, target_prim, target_script, domain, int, method, params, id, "", 0, "", "")

#define enCLEP_RPCRequestSigned(                        key_name,                        target_prim, target_script, domain, int, method, params, id) \
                    _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, key_name, llGetScriptName(), "", target_prim, target_script, domain, int, method, params, id, "", 0, "", "")

#define enCLEP_RequestRoutedSignedRPC(                        key_name,                    target_region, target_prim, target_script, domain, int, method, params, id) \
                          _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, key_name, llGetScriptName(), target_region, target_prim, target_script, domain, int, method, params, id, "", 0, "", "")

/*!
Responds using the CLEP-RPC protocol.
@param string target_prim Target prim UUID ("" for all prims in region).
@param string target_script source_script sent in request.
@param string clep_domain CLEP domain to send message over.
@param integer int Integer sent in request.
@param string method Method sent in request.
@param string id ID sent in request.
@param string result SUCCESSFUL RESPONSES ONLY: Any JSON. If "", will be omitted.
@param integer error_code ERROR RESPONSES ONLY: Any integer. If 0 and both other error_* params are "", the error information will be omitted.
@param string error_message ERROR RESPONSES ONLY: Any string.
@param string error_data ERROR RESPONSES ONLY: Any JSON.
*/
#define _enCLEP_RPCResponse(                                                   target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data) \
                _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, "", llGetScriptName(), "", target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data)

#define _enCLEP_RespondRoutedRPC(                                               target_region, target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data) \
                     _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, "", llGetScriptName(), target_region, target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data)

#define _enCLEP_RPCSignedResponse(                        key_name,                        target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data) \
                      _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, key_name, llGetScriptName(), "", target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data)

#define _enCLEP_RespondRoutedSignedRPC(                        key_name,                    target_region, target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data) \
                           _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, key_name, llGetScriptName(), target_region, target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data)

/*!
Responds with a result using the CLEP-RPC protocol.
@param string target_prim Target prim UUID ("" for all prims in region).
@param string target_script source_script sent in request.
@param string clep_domain CLEP domain to send message over.
@param integer int Integer sent in request.
@param string method Method sent in request.
@param string id ID sent in request.
@param string result Any JSON. This parameter is passed as a raw string, but needs to be valid JSON for CLEP encapsulation, which assumes it is valid JSON.
*/
#define enCLEP_RPCResult(                                                   target_prim, target_script, domain, int, method, params, id, result) \
             _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, "", llGetScriptName(), "", target_prim, target_script, domain, int, method, params, id, result, 0, "", "")

#define enCLEP_RPCRoutedResult(                                               target_region, target_prim, target_script, domain, int, method, params, id, result) \
                   _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, "", llGetScriptName(), target_region, target_prim, target_script, domain, int, method, params, id, result, 0, "", "")

#define enCLEP_RPCSignedResult(                        key_name,                        target_prim, target_script, domain, int, method, params, id, result) \
                   _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, key_name, llGetScriptName(), "", target_prim, target_script, domain, int, method, params, id, result, 0, "", "")

#define enCLEP_RPCRoutedSignedResult(                        key_name,                    target_region, target_prim, target_script, domain, int, method, params, id, result) \
                         _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, key_name, llGetScriptName(), target_region, target_prim, target_script, domain, int, method, params, id, result, 0, "", "")

/*!
Responds with an error using the CLEP-RPC protocol.
@param string target_prim Target prim UUID ("" for all prims in region).
@param string target_script source_script sent in request.
@param string clep_domain CLEP domain to send message over.
@param integer int Integer sent in request.
@param string method Method sent in request.
@param string id ID sent in request.
@param integer error_code Any integer.
@param string error_message Any string.
@param string error_data Any JSON.
*/
#define enCLEP_RPCError(                                                   target_prim, target_script, domain, int, method, params, id,     error_code, error_message, error_data) \
            _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, "", llGetScriptName(), "", target_prim, target_script, domain, int, method, params, id, "", error_code, error_message, error_data)

#define enCLEP_RPCRoutedError(                                               target_region, target_prim, target_script, domain, int, method, params, id,     error_code, error_message, error_data) \
                  _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, "", llGetScriptName(), target_region, target_prim, target_script, domain, int, method, params, id, "", error_code, error_message, error_data)

#define enCLEP_RPCSignedError(                        key_name,                        target_prim, target_script, domain, int, method, params, id,     error_code, error_message, error_data) \
                  _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, key_name, llGetScriptName(), "", target_prim, target_script, domain, int, method, params, id, "", error_code, error_message, error_data)

#define enCLEP_RPCRoutedSignedError(                        key_name,                    target_region, target_prim, target_script, domain, int, method, params, id,     error_code, error_message, error_data) \
                        _enRPC_Send(FLAG_ENRPC_METHOD_CLEP, key_name, llGetScriptName(), target_region, target_prim, target_script, domain, int, method, params, id, "", error_code, error_message, error_data)
