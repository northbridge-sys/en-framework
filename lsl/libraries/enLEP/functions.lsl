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

/*
this is loosely based on JSON-RPC, optimized for LSL's tight memory limits and adding LEP routing metadata: https://en.wikipedia.org/wiki/JSON-RPC
*/
string _enLEP_FormJsonRPC(
    integer flags, // internal flags
    string private_key,
    string source_script,
    string target_region, // only required if relay routing is requested
    string target_prim, // only required if relay routing is requested
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
    /*
    LEP messages are:
    {
        "d":"(any domain string)", <- omitted if blank, but CLEP messages require that this be set to a value for channel hashing
        "ss":llGetScriptName(),
        "ts":"(name of target script)",
        "sp":llGetKey(), <- only required if (1) "s" signature is used, OR (2) relayed routing is requested
        "tp":"(UUID of target prim)", <- only required if relay routing is requested
        "sr":llGetRegionName(), <- only required if relay routing is requested
        "tr":"(name of region that target prim is in)", <- only required if relay routing is requested
        "m":"any.method",
        "p":(any JSON object), <- can be omitted if no params
        "id":"(any string)", <- can be omitted if no response requested (broadcast)
        "r":(any JSON object), <- only for responses that DO NOT return an error
        "e":{ <- only for responses that DO return an error
            "c":(integer error code),
            "m":"(string error message)",
            "d":(any JSON object) <- can be omitted if no error_data provided
        },
        "s":{ <- can be omitted if message unsigned
            "a": llHMAC()/llSignRSA() algorithm,
            "t": llGetTimestamp(),
            "s": HMAC or RSA signature using private_key (see code for underlying "message")
        },
        "i":(any integer) <- omitted for LEP, reserved for CLEP (applied by _enCLEP_SendRPC()); note that int must still be passed to this function if signing; use FLAG_ENLEP_EMBED_INT
    }
    NOTE: these values are not ordered this way!
    LEP passes through target_link and int directly to llMessageLinked().
    No other params are allowed, and the whole spec is reserved for future expansion - all user values must be passed via existing params in the spec
    */
    string addl;
    if (flags & FLAG_ENCLEP_EMBED_INT) addl += ",\"i\":" + (string)int; // embed int into JSON (used by CLEP)
    if (domain != "") addl += ",\"d\":\"" + enString_EscapeQuotes(domain) + "\""; // add domain
    if (id != "") addl += ",\"id\":\"" + enString_EscapeQuotes(id) + "\""; // add id
    if (flags & FLAG_ENCLEP_EMBED_PARAMS && llJsonValueType(params, []) != JSON_INVALID) addl += ",\"p\":" + params; // embed params into JSON (used by CLEP)
    if (llJsonValueType(result, []) != JSON_INVALID) addl += ",\"r\":" + result; // we are sending a response with a result, so add it
    else if (error_code || error_message != "" || error_data != "")
    { // we are sending a response with an error, so add it
        addl += ",\"e\":{\"c\":" + (string)error_code + ",\"m\":\"" + enString_EscapeQuotes(error_message) + "\"";
        if (llJsonValueType(error_data, []) != JSON_INVALID) addl += ",\"d\":" + error_data;
        addl += "}";
    }
    // if no r/e, we are sending a request

    #if defined FEATURE_ENCLEP_ENABLE_ROUTING || defined FEATURE_ENCLEP_ENABLE_SIGNING || defined FEATURE_ENLEP_ENABLE_SIGNING
        if (enKey_IsNotNull(target_prim)) // we are requesting routing, so add routing information
            addl += ",\"sp\":\"" + (string)llGetKey() + "\",\"tp\":\"" + target_prim + "\",\"sr\":\"" + enString_EscapeQuotes(llGetRegionName()) + "\",\"tr\":\"" + enString_EscapeQuotes(target_region) + "\"";
        else if (private_key != "") // we are not requesting routing, but we are signing
            addl += ",\"sp\":\"" + (string)llGetKey() + "\"";
    #endif
    
    #if defined FEATURE_ENCLEP_ENABLE_SIGNING || defined FEATURE_ENLEP_ENABLE_SIGNING
        // signing is enabled - are we signing this message?
        if (private_key != "")
        {
            string timestamp = llGetTimestamp();
            /*
                algorithm
                timestamp
                domain
                source_script
                target_script
                source_prim
                int
                method
                params
                id
                result
                error_code
                error_message
                error_data
                target_prim   \
                source_region  > these three values are only included if we are requesting routing
                target_region /
            */
            #define _ENLEP_OUTBOUND_SIGNATURE_MESSAGE \
                  timestamp \
                + domain \
                + source_script \
                + target_script \
                + (string)llGetKey() \
                + (string)int \
                + method \
                + params \
                + id \
                + result \
                + (string)error_code \
                + error_message \
                + error_data \
                + enString_If(enKey_IsNotNull(target_prim), target_prim + llGetRegionName() + target_region, "")

            if (llGetSubString(private_key, 0, 4) == "-----") addl += ",\"a\":\"" + OVERRIDE_ENLEP_RSA_ALGORITHM + "\",\"t\":\"" + timestamp + "\",\"s\":\"" + llSignRSA(private_key, OVERRIDE_ENLEP_RSA_ALGORITHM + _ENLEP_OUTBOUND_SIGNATURE_MESSAGE, OVERRIDE_ENLEP_RSA_ALGORITHM) + "\""; // use RSA if we were passed an RSA private key
            else addl += ",\"a\":\"" + OVERRIDE_ENLEP_HMAC_ALGORITHM + "\",\"t\":\"" + timestamp + "\",\"s\":\"" + llHMAC(private_key, OVERRIDE_ENLEP_HMAC_ALGORITHM + _ENLEP_OUTBOUND_SIGNATURE_MESSAGE, OVERRIDE_ENLEP_HMAC_ALGORITHM) + "\""; // use HMAC otherwise, since it accepts anything
        }
    #endif

    // return whatever we're sending
    return "{\"ss\":\"" + enString_EscapeQuotes(source_script)
        + "\",\"ts\":\"" + enString_EscapeQuotes(target_script)
        + "\",\"m\":\"" + enString_EscapeQuotes(method)
        + "\"" + addl + "}";
}

/*!
Internal function. Sends a LEP-RPC message via llMessageLinked.
Use enLEP_RequestRPC(), enLEP_RespondRPCResult(), and enLEP_RespondRPCError() instead.
*/
string _enLEP_SendRPC(
    string private_key,
    integer target_link,
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
    #if defined TRACE_ENLEP_SENDRPC
        enLog_TraceParams(
            "_enLEP_SendRPC",
            [
                "private_key",
                "target_link",
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
                enString_If(private_key == "", "", "(hidden)"),
                target_link,
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

    if (!target_link) target_link = OVERRIDE_ENLEP_LINK_MESSAGE_SCOPE;

    llMessageLinked(target_link, int, _enLEP_FormJsonRPC(0, private_key, llGetScriptName(), "", "", target_script, domain, int, method, params, id, result, error_code, error_message, error_data), params);
    return id;
}

/*!
Processes link_message events if EVENT_ENLEP_* is defined.
@param integer 
*/
integer _enLEP_link_message(
    integer l,
    integer int,
    string s,
    string params
)
{
    #if defined TRACE_ENLEP_LINK_MESSAGE
        enLog_TraceParams("_enLEP_link_message", [
            "l",
            "i",
            "s",
            "k"
        ], [
            l,
            int,
            enString_Elem(s),
            enString_Elem(params)
        ]);
    #endif

    /*
    LEP messages are:
    {
        "d":"(any domain string)", <- omitted if blank, but CLEP messages require that this be set to a value for channel hashing
        "ss":llGetScriptName(),
        "ts":"(name of target script)",
        "sp":llGetKey(), <- only required if (1) "s" signature is used, OR (2) relayed routing is requested
        "tp":"(UUID of target prim)", <- only required if relay routing is requested
        "sr":llGetRegionName(), <- only required if relay routing is requested
        "tr":"(name of region that target prim is in)", <- only required if relay routing is requested
        "m":"any.method",
        "p":(any JSON object), <- can be omitted if no params
        "id":"(any string)", <- can be omitted if no response requested (broadcast)
        "r":(any JSON object), <- only for responses that DO NOT return an error
        "e":{ <- only for responses that DO return an error
            "c":(integer error code),
            "m":"(string error message)",
            "d":(any JSON object) <- can be omitted if no error_data provided
        },
        "s":{ <- can be omitted if message unsigned
            "a": llHMAC()/llSignRSA() algorithm,
            "t": llGetTimestamp(),
            "s": HMAC or RSA signature using private_key (see code for underlying "message")
        },
        "i":(any integer) <- omitted for LEP, reserved for CLEP (applied by _enCLEP_SendRPC()); note that int must still be passed to this function if signing; use FLAG_ENLEP_EMBED_INT
    }
    */

    if (llJsonValueType(s, []) != JSON_OBJECT) return -1; // LEP messages are always objects

    string target_script = llJsonGetValue(s, ["ts"]);

    /// generate allowed target_scripts list
    list allowed_targets = ["", llGetScriptName()]; // allow messages targeted to "" (all) and this script only
    #if defined OVERRIDE_ENLEP_ALLOWED_TARGET_SCRIPTS
        allowed_targets += OVERRIDE_ENLEP_ALLOWED_TARGET_SCRIPTS; // allow messages targeted to OVERRIDE_ENLEP_ALLOWED_TARGET_SCRIPTS list as well
    #endif
    #if defined FEATURE_ENLEP_ALLOW_ALL_TARGET_SCRIPTS
        allowed_targets += [target_script]; // always match - this is less efficient, but this flag is only used for debugging anyway
    #endif

    // filter out messages not targeted to a script in allowed_targets
    if (llListFindList(allowed_targets, [target_script]) == -1)
    {
        #if defined FEATURE_ENLEP_ALLOW_FUZZY_TARGET_SCRIPT
            // using substring matching
            if (llSubStringIndex(llGetScriptName(), target_script) == -1) return 1; // discard otherwise valid LEP message, not targeted to us
        #else
            // using exact matching
            return 2; // discard otherwise valid LEP message, not targeted to us
        #endif
    }
    
    string source_script = llJsonGetValue(s, ["ss"]);

    // filter out messages that don't match OVERRIDE_ENLEP_ALLOWED_SOURCE_SCRIPTS list
    #if defined OVERRIDE_ENLEP_ALLOWED_SOURCE_SCRIPTS
        if (llListFindList(OVERRIDE_ENLEP_ALLOWED_SOURCE_SCRIPTS, [source_script]) == -1) return 3; // discard otherwise valid LEP message, not sent from an allowed source script
    #endif

    string id = llJsonGetValue(s, ["id"]);
    if (id == JSON_INVALID) id = "";

    string domain = llJsonGetValue(s, ["d"]);
    if (domain == JSON_INVALID) domain = "";

    string method = llJsonGetValue(s, ["m"]);

    string result = llJsonGetValue(s, ["r"]);
    integer error_code = (integer)llJsonGetValue(s, ["e", "c"]);
    string error_message = llJsonGetValue(s, ["e", "m"]);
    string error_data = llJsonGetValue(s, ["e", "d"]);

    if (domain != OVERRIDE_ENLEP_DOMAIN) return 4; // discard message if it doesn't match the domain OVERRIDE_ENLEP_DOMAIN

    #if defined FEATURE_ENLEP_ENABLE_INBOUND_VERIFICATION
        string algorithm = llJsonGetValue(s, ["s", "a"]);
        string timestamp = llJsonGetValue(s, ["s", "t"]);
        string source_region = llJsonGetValue(s, ["sr"]);
        string source_prim = llJsonGetValue(s, ["sp"]);

        #define _ENLEP_INBOUND_SIGNATURE_MESSAGE \
            algorithm \
            + timestamp \
            + domain \
            + source_script \
            + target_script \
            + source_prim \
            + (string)int \
            + method \
            + params \
            + id \
            + result \
            + (string)error_code \
            + error_message \
            + error_data \
            + enString_If(enKey_IsNotNull(target_prim), target_prim + source_region + target_region, "")

        if (llGetSubString(private_key, 0, 4) == "-----")
        {
            if (!llVerifyRSA(
                OVERRIDE_ENLEP_PUBLIC_KEY, 
                _ENLEP_INBOUND_SIGNATURE_MESSAGE,
                llJsonGetValue(s, ["s", "s"]),
                algorithm)) return 5;
        }
        else
        {
            if (llHMAC(
                OVERRIDE_ENLEP_PRIVATE_KEY, 
                _ENLEP_INBOUND_SIGNATURE_MESSAGE,
                algorithm) != llJsonGetValue(s, ["s", "s"])) return 6;
        }
    #endif

    if (result == JSON_INVALID)
    {
        if (error_message == JSON_INVALID)
        { // request
            #if defined EVENT_ENLEP_RPC_REQUEST && defined TRACE_EVENT_ENLEP_RPC_REQUEST
                enLog_TraceParams(
                    "enlep_rpc_request",
                    [
                        "source_link",
                        "source_script",
                        "target_script",
                        "domain",
                        "int",
                        "method",
                        "params",
                        "id"
                    ], [
                        l, // source_link
                        enString_Elem(source_script),
                        enString_Elem(target_script),
                        domain,
                        int,
                        method,
                        params,
                        id
                    ]
                );
            #endif
            #if defined EVENT_ENLEP_RPC_REQUEST
                enlep_rpc_request(
                    l, // source_link
                    source_script,
                    target_script,
                    domain,
                    int,
                    method,
                    params,
                    id
                );
            #endif
            return 7;
        }

        // error response
        #if defined EVENT_ENLEP_RPC_ERROR && defined TRACE_EVENT_ENLEP_RPC_ERROR
            enLog_TraceParams(
                "enlep_rpc_error",
                [
                    "source_link",
                    "source_script",
                    "target_script",
                    "domain",
                    "int",
                    "method",
                    "params",
                    "id",
                    "error_code",
                    "error_message",
                    "error_data"
                ], [
                    l, // source_link
                    enString_Elem(source_script),
                    enString_Elem(target_script),
                    domain,
                    int,
                    method,
                    params,
                    id,
                    error_code,
                    enString_Elem(error_message),
                    error_data
                ]
            );
        #endif
        #if defined EVENT_ENLEP_RPC_ERROR
            enlep_rpc_error(
                l, // source_link
                source_script,
                target_script,
                domain,
                int,
                method,
                params,
                id,
                error_code,
                error_message,
                error_data
            );
        #endif
        return 8;
    }

    // result response
    #if defined EVENT_ENLEP_RPC_RESULT && defined TRACE_EVENT_ENLEP_RPC_RESULT
        enLog_TraceParams(
            "enlep_rpc_result",
            [
                "source_link",
                "source_script",
                "target_script",
                "domain",
                "int",
                "method",
                "params",
                "id",
                "result"
            ], [
                l, // source_link
                enString_Elem(source_script),
                enString_Elem(target_script),
                domain,
                int,
                method,
                params,
                id,
                result
            ]
        );
    #endif
    #if defined EVENT_ENLEP_RPC_RESULT
        enlep_rpc_result(
            l, // source_link
            source_script,
            target_script,
            domain,
            int,
            method,
            params,
            id,
            result
        );
    #endif
    return 9;
}
