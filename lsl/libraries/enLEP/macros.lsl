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

// internal flags
#define FLAG_ENLEP_TYPE_REQUEST 0x1
#define FLAG_ENLEP_TYPE_RESPONSE 0x2
#define FLAG_ENLEP_STATUS_ERROR 0x80000000

#if !defined OVERRIDE_ENLEP_DOMAIN
    #define OVERRIDE_ENLEP_DOMAIN ""
#endif

#ifndef OVERRIDE_ENLEP_LINK_MESSAGE_SCOPE
    #define OVERRIDE_ENLEP_LINK_MESSAGE_SCOPE LINK_THIS
#endif

#if !defined OVERRIDE_ENLEP_HMAC_ALGORITHM
    #define OVERRIDE_ENLEP_HMAC_ALGORITHM "sha256"
#endif

#if !defined OVERRIDE_ENLEP_RSA_ALGORITHM
    #define OVERRIDE_ENLEP_RSA_ALGORITHM "sha512"
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
#define enLEP_RequestRPC(    target_link, target_script,                        int, method, params, id) \
          _enLEP_SendRPC("", target_link, target_script, OVERRIDE_ENLEP_DOMAIN, int, method, params, id, "", 0, "", "")

#define enLEP_RequestSignedRPC(private_key, target_link, target_script,                        int, method, params, id) \
                _enLEP_SendRPC(private_key, target_link, target_script, OVERRIDE_ENLEP_DOMAIN, int, method, params, id, "", 0, "", "")

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
#define _enLEP_RespondRPC(    target_link, target_script,                        int, method, params, id, result, error_code, error_message, error_data) \
           _enLEP_SendRPC("", target_link, target_script, OVERRIDE_ENLEP_DOMAIN, int, method, params, id, result, error_code, error_message, error_data)

#define _enLEP_RespondSignedRPC(private_key, target_link, target_script,                        int, method, params, id, result, error_code, error_message, error_data) \
                 _enLEP_SendRPC(private_key, target_link, target_script, OVERRIDE_ENLEP_DOMAIN, int, method, params, id, result, error_code, error_message, error_data)

/*!
Responds with a result using the LEP-RPC protocol.
@param integer target_link source_link sent via link_message.
@param string target_script source_script sent in request.
@param integer int Integer sent in request.
@param string method Method sent in request.
@param string id ID sent in request.
@param string result Any JSON object.
*/
#define   enLEP_RespondRPCResult(    target_link, target_script,                        int, method, params, id, result) \
                  _enLEP_SendRPC("", target_link, target_script, OVERRIDE_ENLEP_DOMAIN, int, method, params, id, result, 0, "", "")

#define enLEP_RespondRPCResultSigned(private_key, target_link, target_script,                        int, method, params, id, result) \
                      _enLEP_SendRPC(private_key, target_link, target_script, OVERRIDE_ENLEP_DOMAIN, int, method, params, id, result, 0, "", "")

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
#define enLEP_RespondRPCError(    target_link, target_script,                        int, method, params, id,     error_code, error_message, error_data) \
               _enLEP_SendRPC("", target_link, target_script, OVERRIDE_ENLEP_DOMAIN, int, method, params, id, "", error_code, error_message, error_data)

#define enLEP_RespondRPCErrorSigned(private_key, target_link, target_script,                        int, method, params, id,     error_code, error_message, error_data) \
                     _enLEP_SendRPC(private_key, target_link, target_script, OVERRIDE_ENLEP_DOMAIN, int, method, params, id, "", error_code, error_message, error_data)
