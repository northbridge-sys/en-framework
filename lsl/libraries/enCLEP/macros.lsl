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

// NOTE: do not use FLAG_ENCLEP_LISTEN_OWNERONLY across region borders!
#define FLAG_ENCLEP_LISTEN_OWNERONLY 0x1
#define FLAG_ENCLEP_LISTEN_REMOVE 0x80000000

#define FLAG_ENCLEP_EMBED_INT 0x1
#define FLAG_ENCLEP_EMBED_PARAMS 0x2

#ifndef OVERRIDE_INTEGER_ENCLEP_RESERVE_LISTENS
    #define OVERRIDE_INTEGER_ENCLEP_RESERVE_LISTENS 0
#endif

// used by enCLEP_DialogListen()
integer _ENCLEP_DIALOG_LSN;

list _ENCLEP_DOMAINS; // domain, flags, handle
#define _ENCLEP_DOMAINS_STRIDE 3

/*
enCLEP_Channel is the hashing algorithm that converts a domain into a channel number.
This is used to enforce channel separation on different domains. This reduces script time for llRegionSay calls.
enCLEP_Channel can also be used directly in llListen for a relatively safe llDialog channel (see enCLEP_DialogChannel()).
enCLEP channels are always negative, so we just set the 0x80000000 bit to force a negative integer of some kind.
This also naturally avoids PUBLIC_CHANNEL (0x0 -> 0x80000000) and DEBUG_CHANNEL (0x7FFFFFFF -> 0xFFFFFFFF).
*/
#define enCLEP_Channel(domain) \
    (llHash(domain) | CONST_INTEGER_NEGATIVE)

#define enCLEP_Reserved() \
    (!!_ENCLEP_DIALOG_LSN + OVERRIDE_INTEGER_ENCLEP_RESERVE_LISTENS)

/*
enCLEP_DialogChannel can be used to get the channel we are listing to if enCLEP_DialogListen was called.
*/
#define enCLEP_DialogChannel() \
    enCLEP_Channel((string)llGetInventoryKey(llGetScriptName()))

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
#define enCLEP_RequestRPC(        target_prim, target_script, domain, int, method, params, id) \
          _enCLEP_SendRPC("", "", target_prim, target_script, domain, int, method, params, id, "", 0, "", "")

#define enCLEP_RequestRoutedRPC(    target_region, target_prim, target_script, domain, int, method, params, id) \
                _enCLEP_SendRPC("", target_region, target_prim, target_script, domain, int, method, params, id, "", 0, "", "")

#define enCLEP_RequestSignedRPC(private_key,     target_prim, target_script, domain, int, method, params, id) \
                _enCLEP_SendRPC(private_key, "", target_prim, target_script, domain, int, method, params, id, "", 0, "", "")

#define enCLEP_RequestRoutedSignedRPC(private_key, target_region, target_prim, target_script, domain, int, method, params, id) \
                      _enCLEP_SendRPC(private_key, target_region, target_prim, target_script, domain, int, method, params, id, "", 0, "", "")

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
#define _enCLEP_RespondRPC(        target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data) \
           _enCLEP_SendRPC("", "", target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data)

#define _enCLEP_RespondRoutedRPC(    target_region, target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data) \
                 _enCLEP_SendRPC("", target_region, target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data)

#define _enCLEP_RespondSignedRPC(private_key,     target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data) \
                 _enCLEP_SendRPC(private_key, "", target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data)

#define _enCLEP_RespondRoutedSignedRPC(private_key, target_region, target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data) \
                       _enCLEP_SendRPC(private_key, target_region, target_prim, target_script, domain, int, method, params, id, result, error_code, error_message, error_data)

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
#define enCLEP_RespondRPCResult(        target_prim, target_script, domain, int, method, params, id, result) \
                _enCLEP_SendRPC("", "", target_prim, target_script, domain, int, method, params, id, result, 0, "", "")

#define enCLEP_RespondRoutedRPCResult(    target_region, target_prim, target_script, domain, int, method, params, id, result) \
                      _enCLEP_SendRPC("", target_region, target_prim, target_script, domain, int, method, params, id, result, 0, "", "")

#define enCLEP_RespondSignedRPCResult(private_key,     target_prim, target_script, domain, int, method, params, id, result) \
                      _enCLEP_SendRPC(private_key, "", target_prim, target_script, domain, int, method, params, id, result, 0, "", "")

#define enCLEP_RespondRoutedSignedRPCResult(private_key, target_region, target_prim, target_script, domain, int, method, params, id, result) \
                            _enCLEP_SendRPC(private_key, target_region, target_prim, target_script, domain, int, method, params, id, result, 0, "", "")

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
#define enCLEP_RespondRPCError(        target_prim, target_script, domain, int, method, params, id,     error_code, error_message, error_data) \
               _enCLEP_SendRPC("", "", target_prim, target_script, domain, int, method, params, id, "", error_code, error_message, error_data)

#define enCLEP_RespondRoutedRPCError(    target_region, target_prim, target_script, domain, int, method, params, id,     error_code, error_message, error_data) \
                     _enCLEP_SendRPC("", target_region, target_prim, target_script, domain, int, method, params, id, "", error_code, error_message, error_data)

#define enCLEP_RespondSignedRPCError(private_key,     target_prim, target_script, domain, int, method, params, id,     error_code, error_message, error_data) \
                     _enCLEP_SendRPC(private_key, "", target_prim, target_script, domain, int, method, params, id, "", error_code, error_message, error_data)

#define enCLEP_RespondRoutedSignedRPCError(private_key, target_region, target_prim, target_script, domain, int, method, params, id,     error_code, error_message, error_data) \
                           _enCLEP_SendRPC(private_key, target_region, target_prim, target_script, domain, int, method, params, id, "", error_code, error_message, error_data)
