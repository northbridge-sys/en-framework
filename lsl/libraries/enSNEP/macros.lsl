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

// used for general-purpose web server communication
#define enSNEP_RPCRequest(                                               target_url,             int, method, params, id) \
              _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, "", llGetScriptName(), target_url, "", "", "", int, method, params, id, "", 0, "", "")

#define _enSNEP_RPCResponse(                                                   target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data) \
                _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, "", llGetScriptName(), "", target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data)

#define enSNEP_RPCResult(                                                   target_prim, target_script, domain, int, method, params, id, result) \
             _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, "", llGetScriptName(), "", target_prim, target_script, domain, int, method, params, id, result, 0, "", "")

#define enSNEP_RPCError(                                                   target_prim, target_script, domain, int, method, params, id,     error_code, error_message, error_data) \
            _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, "", llGetScriptName(), "", target_prim, target_script, domain, int, method, params, id, "", error_code, error_message, error_data)

          
#define enSNEP_RPCRequestSigned(                        key_name,                    target_url,             int, method, params, id) \
                    _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, key_name, llGetScriptName(), target_url, "", "", "", int, method, params, id, "", 0, "", "")

#define _enSNEP_RPCSignedResponse(                        key_name,                    target_url,             int, method, params, id, result, error_code, error_message, error_data) \
                      _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, key_name, llGetScriptName(), target_url, "", "", "", int, method, params, id, result, error_code, error_message, error_data)

#define enSNEP_RPCResultSigned(                        key_name,                        target_prim, target_script, domain, int, method, params, id, result) \
                   _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, key_name, llGetScriptName(), "", target_prim, target_script, domain, int, method, params, id, result, 0, "", "")

#define enSNEP_RPCErrorSigned(                        key_name,                        target_prim, target_script, domain, int, method, params, id,     error_code, error_message, error_data) \
                  _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, key_name, llGetScriptName(), "", target_prim, target_script, domain, int, method, params, id, "", error_code, error_message, error_data)

// used for SNEP relays
#define enSNEP_RPCRequestRelayed(                                               relay_url, target_prim, target_script, domain, int, method, params, id) \
                     _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, "", llGetScriptName(), relay_url, target_prim, target_script, domain, int, method, params, id, "", 0, "", "")

#define _enSNEP_RPCRespondRelayed(                                               relay_url, target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data) \
                      _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, "", llGetScriptName(), relay_url, target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data)

#define enSNEP_RPCResultRelayed(                                               relay_url, target_prim, target_script, domain, int, method, params, id, result) \
                    _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, "", llGetScriptName(), relay_url, target_prim, target_script, domain, int, method, params, id, result, 0, "", "")

#define enSNEP_RPCErrorRelayed(                                               relay_url, target_prim, target_script, domain, int, method, params, id,     error_code, error_message, error_data) \
                   _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, "", llGetScriptName(), relay_url, target_prim, target_script, domain, int, method, params, id, "", error_code, error_message, error_data)


#define enSNEP_RPCRequestRelayedSigned(                        key_name,                    relay_url, target_prim, target_script, domain, int, method, params, id) \
                           _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, llGetScriptName(), key_name, relay_url, target_prim, target_script, domain, int, method, params, id, "", 0, "", "")

#define _enSNEP_RPCRespondRelayedSigned(                        key_name,                    relay_url, target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data) \
                            _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, key_name, llGetScriptName(), relay_url, target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data)

#define enSNEP_RPCResultRelayedSigned(                        key_name,                    relay_url, target_prim, target_script, domain, int, method, params, id, result) \
                          _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, key_name, llGetScriptName(), relay_url, target_prim, target_script, domain, int, method, params, id, result, 0, "", "")

#define enSNEP_RPCErrorRelayedSigned(                        key_name,                    relay_url, target_prim, target_script, domain, int, method, params, id,     error_code, error_message, error_data) \
                         _enRPC_Send(FLAG_ENRPC_METHOD_SNEP, key_name, llGetScriptName(), relay_url, target_prim, target_script, domain, int, method, params, id, "", error_code, error_message, error_data)
