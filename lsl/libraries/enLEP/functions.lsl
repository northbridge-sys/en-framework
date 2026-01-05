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
            "h": HMAC hash using private_key (see code for underlying "message")     \ either "h" or "s" only!
            "s": RSA signature using private_key (see code for underlying "message") / 
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

            if (llGetSubString(private_key, 0, 4) == "-----") addl += ",\"s\":{\"a\":\"" + OVERRIDE_ENLEP_RSA_ALGORITHM + "\",\"t\":\"" + timestamp + "\",\"s\":\"" + llSignRSA(private_key, OVERRIDE_ENLEP_RSA_ALGORITHM + _ENLEP_OUTBOUND_SIGNATURE_MESSAGE, OVERRIDE_ENLEP_RSA_ALGORITHM) + "\"}"; // use RSA if we were passed an RSA private key
            else addl += ",\"s\":{\"a\":\"" + OVERRIDE_ENLEP_HMAC_ALGORITHM + "\",\"t\":\"" + timestamp + "\",\"h\":\"" + llHMAC(private_key, OVERRIDE_ENLEP_HMAC_ALGORITHM + _ENLEP_OUTBOUND_SIGNATURE_MESSAGE, OVERRIDE_ENLEP_HMAC_ALGORITHM) + "\"}"; // use HMAC otherwise, since it accepts anything
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
    integer i,
    string s,
    string k
)
{
    integer e = _enLEP_ProcessRPC(
        "", // source_prim
        l, // source_link
        s, // json
        i, // int (used only if not in json)
        k // params (used only if not in json)
    );

    #if defined TRACE_ENLEP_LINK_MESSAGE
        enLog_TraceParamsResult("_enLEP_link_message", [
            "l",
            "i",
            "s",
            "k"
        ], [
            l,
            i,
            enString_Elem(s),
            enString_Elem(k)
        ],
        (string)e
    );
    #endif

    return e;
}

integer _enLEP_ProcessRPC(
    string source_prim,
    integer source_link,
    string json,
    integer int,
    string params
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
    */

    if (llJsonValueType(json, []) != JSON_OBJECT) return -1; // LEP messages are always objects

    #if defined FEATURE_ENLEP_EXPERIMENTAL_PARSING
        string domain;
        string source_script;
        string target_script;
        string target_prim;
        string source_region;
        string target_region;
        integer int;
        string method;
        string params;
        string id;
        string result;
        integer error_code;
        string error_message;
        string error_data;
        string algorithm;
        string timestamp;
        string signature;
        string hash;

        /*
        uses experimental llJson2List parser for performance
        */
        list parsed = llJson2List(json);
        integer i;
        integer l = llGetListLength(parsed) / 2;
        for (i = 0; i < l; i++)
        {
            string name = llList2String(parsed, i * 2);
            string data = llList2String(parsed, i * 2 + 1);
            if (name == "d") domain = data;
            else if (name == "ss") source_script = data;
            else if (name == "ts") target_script = data;
            else if (name == "sp") source_prim = data;
            else if (name == "tp") target_prim = data;
            else if (name == "sr") source_region = data;
            else if (name == "tr") target_region = data;
            else if (name == "i") int = (integer)data;
            else if (name == "m") method = data;
            else if (name == "p") params = data;
            else if (name == "id") id = data;
            else if (name == "r") result = data;
            else if (name == "e")
            {
                error_code = (integer)llJsonGetValue(data, ["c"]);
                error_message = llJsonGetValue(data, ["m"]);
                if (llJsonValueType(data, ["d"]) != JSON_INVALID) error_data = llJsonGetValue(data, ["d"]);
            }
            else if (name == "s")
            {
                algorithm = llJsonGetValue(data, ["a"]);
                timestamp = llJsonGetValue(data, ["t"]);
                signature = llJsonGetValue(data, ["s"]);
                hash = llJsonGetValue(data, ["h"]);
            }
        }
    #endif

    string target_region = llJsonGetValue(json, ["tr"]);
    if (target_region == JSON_INVALID) target_region = "";
    #if !defined FEATURE_ENLEP_ALLOW_ALL_TARGET_REGIONS
        if (target_region != "")
        {
            if (target_region != llGetRegionName()) return 1; // not targeted to this region
        }
    #endif

    #if !defined FEATURE_ENLEP_EXPERIMENTAL_PARSING
        string target_prim = llJsonGetValue(json, ["tp"]);
        if (target_prim == JSON_INVALID) target_prim = "";
    #endif
    #if !defined FEATURE_ENLEP_ALLOW_ALL_TARGET_PRIMS
        if (target_prim != "")
        {
            if (target_prim != (string)llGetKey()) return 2; // not targeted to this prim
        }
    #endif

    string target_script = llJsonGetValue(json, ["ts"]);
    list allowed_targets = ["", llGetScriptName()]; // allow messages targeted to "" (all) and this script only
    #if defined OVERRIDE_ENLEP_ALLOWED_TARGET_SCRIPTS
        allowed_targets += OVERRIDE_ENLEP_ALLOWED_TARGET_SCRIPTS; // allow messages targeted to OVERRIDE_ENLEP_ALLOWED_TARGET_SCRIPTS list as well
    #endif
    #if !defined FEATURE_ENLEP_ALLOW_ALL_TARGET_SCRIPTS
    // filter out messages not targeted to a script in allowed_targets
        if (llListFindList(allowed_targets, [target_script]) == -1)
        {
    #endif
            #if !defined FEATURE_ENLEP_ALLOW_ALL_TARGET_SCRIPTS && defined FEATURE_ENLEP_ALLOW_FUZZY_TARGET_SCRIPT
                // using substring matching
                if (llSubStringIndex(llGetScriptName(), target_script) == -1) return 3; // discard otherwise valid LEP message, not targeted to us
            #endif
            #if !defined FEATURE_ENLEP_ALLOW_ALL_TARGET_SCRIPTS && !defined FEATURE_ENLEP_ALLOW_FUZZY_TARGET_SCRIPT
                // using exact matching
                return 4; // discard otherwise valid LEP message, not targeted to us
            #endif
    #if !defined FEATURE_ENLEP_ALLOW_ALL_TARGET_SCRIPTS
        }
    #endif

    // TODO: it may be faster to dump the json to an object list, and iterate through it to fill out the local vars? but will waste more memory
    
    string source_region = llJsonGetValue(json, ["sr"]);
    if (source_region == JSON_INVALID) source_region = llGetRegionName();

    if (source_prim == "") source_prim = llJsonGetValue(json, ["sp"]);
    if (source_prim == JSON_INVALID) source_prim = "";

    string source_script = llJsonGetValue(json, ["ss"]);

    // filter out messages that don't match OVERRIDE_ENLEP_ALLOWED_SOURCE_SCRIPTS list
    #if defined OVERRIDE_ENLEP_ALLOWED_SOURCE_SCRIPTS
        if (llListFindList(OVERRIDE_ENLEP_ALLOWED_SOURCE_SCRIPTS, [source_script]) == -1) return 5; // discard otherwise valid LEP message, not sent from an allowed source script
    #endif

    string id = llJsonGetValue(json, ["id"]);
    if (id == JSON_INVALID) id = "";

    string domain = llJsonGetValue(json, ["d"]);
    if (domain == JSON_INVALID) domain = "";

    string method = llJsonGetValue(json, ["m"]);
    if (llJsonValueType(json, ["i"]) != JSON_NUMBER) int = (integer)llJsonGetValue(json, ["i"]); // int was embedded, so use the embedded copy (probably forwarded from CLEP)
    if (llJsonValueType(json, ["p"]) != JSON_INVALID) params = llJsonGetValue(json, ["p"]); // params was embedded, so use the embedded copy (probably forwarded from CLEP)

    string result = llJsonGetValue(json, ["r"]);
    integer error_code = (integer)llJsonGetValue(json, ["e", "c"]);
    string error_message = llJsonGetValue(json, ["e", "m"]);
    string error_data = llJsonGetValue(json, ["e", "d"]);

    if (source_link != -1 && domain != OVERRIDE_ENLEP_DOMAIN) return 6; // discard message if it doesn't match the domain OVERRIDE_ENLEP_DOMAIN and received via link_message

    string key_name;

    #if defined FEATURE_ENLEP_ENABLE_VERIFICATION
        if (llJsonValueType(json, ["s"]) == JSON_OBJECT)
        {
            string algorithm = llJsonGetValue(json, ["s", "a"]);
            string timestamp = llJsonGetValue(json, ["s", "t"]);

            if (llAbs(enDate_TimestampDiffToSeconds(timestamp, llGetTimestamp())) < OVERRIDE_ENLEP_SIGNATURE_EXPIRY)
            {
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
                    + enString_If(result == JSON_INVALID, "", result) \
                    + (string)error_code \
                    + enString_If(error_message == JSON_INVALID, "", error_message) \
                    + enString_If(error_data == JSON_INVALID, "", error_data) \
                    + enString_If(source_link == -1, (string)llGetKey() + source_region + target_region, "")

                // iterate through all known keys until we find one that works
                integer valid;
                integer index;
                integer max = llGetListLength(_ENLEP_KEYS) / 2;
                string use_key;
                do
                {
                    use_key = llList2String(_ENLEP_KEYS, index * 2 + 1);
                    if (use_key != "")
                    {
                        // only attempt llVerifyRSA() if it looks like we're using an RSA public key, since it's slow
                        string hmac = llJsonGetValue(json, ["s", "h"]);
                        if (hmac == JSON_INVALID) valid = llVerifyRSA(use_key, _ENLEP_INBOUND_SIGNATURE_MESSAGE, llJsonGetValue(json, ["s", "s"]), algorithm);
                        else valid = (llHMAC(use_key, _ENLEP_INBOUND_SIGNATURE_MESSAGE, algorithm) == hmac);
                    }
                }
                while (!valid && ++index < max);

                if (valid) key_name = llList2String(_ENLEP_KEYS, (index - 1) * 2);
            }
        }
    #endif

    if (source_link != -1)
    { // we received this message via link_message, so process it via enlep_rpc_*()
        if (result == JSON_INVALID)
        {
            if (error_message == JSON_INVALID)
            { // request
                #if defined EVENT_ENLEP_RPC_REQUEST && defined TRACE_EVENT_ENLEP_RPC_REQUEST
                    enLog_TraceParams(
                        "enlep_rpc_request",
                        [
                            "key_name",
                            "source_link",
                            "source_script",
                            "target_script",
                            "domain",
                            "int",
                            "method",
                            "params",
                            "id"
                        ], [
                            enString_Elem(key_name),
                            source_link,
                            enString_Elem(source_script),
                            enString_Elem(target_script),
                            enString_Elem(domain),
                            int,
                            enString_Elem(method),
                            params,
                            enString_Elem(id)
                        ]
                    );
                #endif
                #if defined EVENT_ENLEP_RPC_REQUEST
                    enlep_rpc_request(
                        key_name,
                        source_link,
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
                        "key_name",
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
                        enString_Elem(key_name),
                        source_link,
                        enString_Elem(source_script),
                        enString_Elem(target_script),
                        enString_Elem(domain),
                        int,
                        enString_Elem(method),
                        params,
                        enString_Elem(id),
                        error_code,
                        enString_Elem(error_message),
                        error_data
                    ]
                );
            #endif
            #if defined EVENT_ENLEP_RPC_ERROR
                enlep_rpc_error(
                    key_name,
                    source_link,
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
                    "key_name",
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
                    enString_Elem(key_name),
                    source_link,
                    enString_Elem(source_script),
                    enString_Elem(target_script),
                    enString_Elem(domain),
                    int,
                    enString_Elem(method),
                    params,
                    enString_Elem(id),
                    result
                ]
            );
        #endif
        #if defined EVENT_ENLEP_RPC_RESULT
            enlep_rpc_result(
                key_name,
                source_link,
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

    // we received this message via listen, so process it via enclep_rpc_*()
    if (result == JSON_INVALID)
    {
        if (error_message == JSON_INVALID)
        { // request
            #if defined EVENT_ENCLEP_RPC_REQUEST && defined TRACE_EVENT_ENCLEP_RPC_REQUEST
                enLog_TraceParams(
                    "enclep_rpc_request",
                    [
                        "key_name",
                        "source_region",
                        "source_prim",
                        "source_script",
                        "target_script",
                        "domain",
                        "int",
                        "method",
                        "params",
                        "id"
                    ], [
                        enString_Elem(key_name),
                        enString_Elem(source_region),
                        enPrim_Elem(source_prim),
                        enString_Elem(source_script),
                        enString_Elem(target_script),
                        enString_Elem(domain),
                        int,
                        enString_Elem(method),
                        params,
                        enString_Elem(id)
                    ]
                );
            #endif
            #if defined EVENT_ENCLEP_RPC_REQUEST
                enclep_rpc_request(
                    key_name,
                    source_region,
                    source_prim,
                    source_script,
                    target_script,
                    domain,
                    int,
                    method,
                    params,
                    id
                );
            #endif
            return 10;
        }

        // error response
        #if defined EVENT_ENCLEP_RPC_ERROR && defined TRACE_EVENT_ENCLEP_RPC_ERROR
            enLog_TraceParams(
                "enclep_rpc_error",
                [
                    "key_name",
                    "source_region",
                    "source_prim",
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
                    enString_Elem(key_name),
                    enString_Elem(source_region),
                    enPrim_Elem(source_prim),
                    enString_Elem(source_script),
                    enString_Elem(target_script),
                    enString_Elem(domain),
                    int,
                    enString_Elem(method),
                    params,
                    enString_Elem(id),
                    error_code,
                    enString_Elem(error_message),
                    error_data
                ]
            );
        #endif
        #if defined EVENT_ENCLEP_RPC_ERROR
            enclep_rpc_error(
                key_name,
                source_region,
                source_prim,
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
        return 11;
    }

    // result response
    #if defined EVENT_ENCLEP_RPC_RESULT && defined TRACE_EVENT_ENCLEP_RPC_RESULT
        enLog_TraceParams(
            "enclep_rpc_result",
            [
                "key_name",
                "source_region",
                "source_prim",
                "source_script",
                "target_script",
                "domain",
                "int",
                "method",
                "params",
                "id",
                "result"
            ], [
                enString_Elem(key_name),
                enString_Elem(source_region),
                enPrim_Elem(source_prim),
                enString_Elem(source_script),
                enString_Elem(target_script),
                enString_Elem(domain),
                int,
                enString_Elem(method),
                params,
                enString_Elem(id),
                result
            ]
        );
    #endif
    #if defined EVENT_ENCLEP_RPC_RESULT
        enclep_rpc_result(
            key_name,
            source_region,
            source_prim,
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
    return 12;
}

/*!
Enrolls a key.
For HMAC keys, use the single shared key.
For RSA key pairs, use the RSA PUBLIC key.
@param string key_name The identifer for this key.
@param string key_data The HMAC shared or RSA public key.
@return integer TRUE for enrolled, FALSE if already enrolled (the key must be removed using enLEP_Unenroll() first)
*/
integer enLEP_EnrollKey(
    string key_name,
    string key_data
)
{
    if (key_name == "" || key_data == "") return FALSE;
    if (llListFindList(llList2ListSlice(_ENLEP_KEYS, 0, -1, 2, 0), [key_name]) != -1)
    {
        enLog_Warn("enLEP_EnrollKey attempted on existing key \"" + key_name + "\"");
        return FALSE;
    }
    enLog_Trace("Enrolled key \"" + key_name + "\"");
    _ENLEP_KEYS += [key_name, key_data];
    return TRUE;
}

/*!
Unenrolls a key.
@param string key_name The identifer for this key.
@return integer TRUE for unenrolled, FALSE if not currently enrolled.
*/
integer enLEP_UnenrollKey(
    string key_name
)
{
    integer index = llListFindList(llList2ListSlice(_ENLEP_KEYS, 0, -1, 2, 0), [key_name]);
    if (index == -1) return FALSE;
    _ENLEP_KEYS = llDeleteSubList(_ENLEP_KEYS, index * 2, (index + 1) * 2 - 1);
    enLog_Trace("Unenrolled key \"" + key_name + "\"");
    return TRUE;
}

/*!
Gets an enrolled key.
@param string key_name The identifer for this key.
@return string HMAC shared or RSA public key. WARNING: It's possible to leak HMAC shared keys if you are exposing RSA public keys and also use HMAC!
*/
string enLEP_GetKey(
    string key_name
)
{
    integer index = llListFindList(llList2ListSlice(_ENLEP_KEYS, 0, -1, 2, 0), [key_name]);
    if (index == -1)
    {
        enLog_Warn("Key \"" + key_name + "\" not enrolled");
        return "";
    }
    return llList2String(_ENLEP_KEYS, index * 2 + 1);
}
