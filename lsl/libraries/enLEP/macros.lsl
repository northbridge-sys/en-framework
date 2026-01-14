/*
enLEP.lsl
Library
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

#ifndef OVERRIDE_ENLEP_LINK_MESSAGE_SCOPE
    #define OVERRIDE_ENLEP_LINK_MESSAGE_SCOPE LINK_THIS
#endif

/*!
Sends a request using the LEP-RPC protocol.
@param integer target_link Target link number.
@param string target_script Target script name ("" for all in targeted link(s)).
@param integer int Any integer.
@param string method Any method, separated by periods ("."), e.g.: system.display.pixel.color
@param string params Any JSON object.
@param string id Any string. If "", will be omitted.
*/
#define enLEP_RPCRequest(                                                       target_link,      target_script,                        int, method, params, id) \
             _enRPC_Send(FLAG_ENRPC_METHOD_LEP, "", llGetScriptName(), (string)(target_link), "", target_script, OVERRIDE_ENRPC_LEP_DOMAIN, int, method, params, id, "", 0, "", "")

#define enLEP_RPCRequestSigned(                       key_name,                             target_link,      target_script,                        int, method, params, id) \
                   _enRPC_Send(FLAG_ENRPC_METHOD_LEP, key_name, llGetScriptName(), (string)(target_link), "", target_script, OVERRIDE_ENRPC_LEP_DOMAIN, int, method, params, id, "", 0, "", "")

/*!
Responds using the LEP-RPC protocol.
@param integer target_link source_link sent via link_message.
@param string target_script source_script sent in request.
@param integer int Integer sent in request.
@param string method Method sent in request.
@param string id ID sent in request.
@param string result SUCCESSFUL RESPONSES ONLY: Any JSON object. If "", will be omitted.
@param integer error_code ERROR RESPONSES ONLY: Any integer. If 0 and both other error_* params are "", the error information will be omitted.
@param string error_message ERROR RESPONSES ONLY: Any string.
@param string error_data ERROR RESPONSES ONLY: Any JSON object.
*/
#define _enLEP_RPCResponse(                                                       target_link,      target_script,                        int, method, params, id, result, error_code, error_message, error_data) \
               _enRPC_Send(FLAG_ENRPC_METHOD_LEP, "", llGetScriptName(), (string)(target_link), "", target_script, OVERRIDE_ENRPC_LEP_DOMAIN, int, method, params, id, result, error_code, error_message, error_data)

#define _enLEP_RPCSignedResponse(                       key_name,                             target_link,      target_script,                        int, method, params, id, result, error_code, error_message, error_data) \
                     _enRPC_Send(FLAG_ENRPC_METHOD_LEP, key_name, llGetScriptName(), (string)(target_link), "", target_script, OVERRIDE_ENRPC_LEP_DOMAIN, int, method, params, id, result, error_code, error_message, error_data)

/*!
Responds with a result using the LEP-RPC protocol.
@param integer target_link source_link sent via link_message.
@param string target_script source_script sent in request.
@param integer int Integer sent in request.
@param string method Method sent in request.
@param string id ID sent in request.
@param string result Any JSON object.
*/
#define enLEP_RPCResult(                                                       target_link,      target_script,                        int, method, params, id, result) \
            _enRPC_Send(FLAG_ENRPC_METHOD_LEP, "", llGetScriptName(), (string)(target_link), "", target_script, OVERRIDE_ENRPC_LEP_DOMAIN, int, method, params, id, result, 0, "", "")

#define enLEP_RPCSignedResult(                       key_name,                             target_link,      target_script,                        int, method, params, id, result) \
                  _enRPC_Send(FLAG_ENRPC_METHOD_LEP, key_name, llGetScriptName(), (string)(target_link), "", target_script, OVERRIDE_ENRPC_LEP_DOMAIN, int, method, params, id, result, 0, "", "")

/*!
Responds with an error using the LEP-RPC protocol.
@param integer target_link source_link sent via link_message.
@param string target_script source_script sent in request.
@param integer int Integer sent in request.
@param string method Method sent in request.
@param string id ID sent in request.
@param integer error_code Any integer.
@param string error_message Any string.
@param string error_data Any JSON object.
*/
#define enLEP_RPCError(                                                       target_link,      target_script,                        int, method, params, id,     error_code, error_message, error_data) \
           _enRPC_Send(FLAG_ENRPC_METHOD_LEP, "", llGetScriptName(), (string)(target_link), "", target_script, OVERRIDE_ENRPC_LEP_DOMAIN, int, method, params, id, "", error_code, error_message, error_data)

#define enLEP_RPCSignedError(                       key_name,                             target_link,      target_script,                        int, method, params, id,     error_code, error_message, error_data) \
                 _enRPC_Send(FLAG_ENRPC_METHOD_LEP, key_name, llGetScriptName(), (string)(target_link), "", target_script, OVERRIDE_ENRPC_LEP_DOMAIN, int, method, params, id, "", error_code, error_message, error_data)
