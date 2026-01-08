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

string _enRPC_Marshal(
    integer flags, // internal flags
    string key_name,
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
    enRPC implements LEP/CLEP/SNEP messages, which are defined as the following (blank strings may be omitted):
    {
        "d":"(any domain string)",
        "ss":llGetScriptName(),
        "ts":"(name of target script)",
        "sp":llGetKey(), <- only required if (1) "s" signature is used, OR (2) relayed routing is requested
        "tp":"(UUID of target prim)", <- only required if relay routing is requested
        "sr":llGetRegionName(), <- only required if relay routing is requested
        "tr":"(name of region that target prim is in)", <- only required if relay routing is requested
        "i":(any integer), <- only added if FLAG_ENRPC_EMBED_INT is used
        "m":"any.method",
        "p":(any JSON object), <- only added if FLAG_ENRPC_EMBED_PARAMS is used
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
        }
    }
    NOTE: these values are not ordered this way!
    */
    string addl;
    if (flags & FLAG_ENRPC_EMBED_INT) addl += ",\"i\":" + (string)int; // embed int into JSON (used by CLEP)
    if (domain != "") addl += ",\"d\":\"" + enString_EscapeQuotes(domain) + "\""; // add domain
    if (id != "") addl += ",\"id\":\"" + enString_EscapeQuotes(id) + "\""; // add id
    if (flags & FLAG_ENRPC_EMBED_PARAMS && llJsonValueType(params, []) != JSON_INVALID) addl += ",\"p\":" + params; // embed params into JSON (used by CLEP)
    if (llJsonValueType(result, []) != JSON_INVALID) addl += ",\"r\":" + result; // we are sending a response with a result, so add it
    else if (error_code || error_message != "" || error_data != "")
    { // we are sending a response with an error, so add it
        addl += ",\"e\":{\"c\":" + (string)error_code + ",\"m\":\"" + enString_EscapeQuotes(error_message) + "\"";
        if (llJsonValueType(error_data, []) != JSON_INVALID) addl += ",\"d\":" + error_data;
        addl += "}";
    }
    // if no r/e, we are sending a request

    #if defined FEATURE_ENCLEP_ENABLE_ROUTING || defined FEATURE_ENRPC_ENABLE_SIGNING
        if (enKey_IsNotNull(target_prim)) // we are requesting routing, so add routing information
            addl += ",\"sp\":\"" + (string)llGetKey() + "\",\"tp\":\"" + target_prim + "\",\"sr\":\"" + enString_EscapeQuotes(llGetRegionName()) + "\",\"tr\":\"" + enString_EscapeQuotes(target_region) + "\"";
        else if (key_name != "") // we are not requesting routing, but we are signing
            addl += ",\"sp\":\"" + (string)llGetKey() + "\"";
    #endif
    
    #if defined FEATURE_ENRPC_ENABLE_SIGNING
        // signing is enabled - are we signing this message?
        string private_key = enRPC_GetKey(key_name); // import private_key from ENRPC_KEYS

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
            #define _ENRPC_OUTBOUND_SIGNATURE_MESSAGE \
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

            #if defined TRACE_ENRPC_OUTBOUND_SIGNATURE_MESSAGE
                enLog_Trace(_ENRPC_OUTBOUND_SIGNATURE_MESSAGE);
            #endif
            
            if (llGetSubString(private_key, 0, 4) == "-----") addl += ",\"s\":{\"a\":\"" + OVERRIDE_ENRPC_RSA_ALGORITHM + "\",\"t\":\"" + timestamp + "\",\"r\":\"" + llSignRSA(private_key, OVERRIDE_ENRPC_RSA_ALGORITHM + _ENRPC_OUTBOUND_SIGNATURE_MESSAGE, OVERRIDE_ENRPC_RSA_ALGORITHM) + "\"}"; // use RSA if we were passed an RSA private key
            else addl += ",\"s\":{\"a\":\"" + OVERRIDE_ENRPC_HMAC_ALGORITHM + "\",\"t\":\"" + timestamp + "\",\"h\":\"" + llHMAC(private_key, OVERRIDE_ENRPC_HMAC_ALGORITHM + _ENRPC_OUTBOUND_SIGNATURE_MESSAGE, OVERRIDE_ENRPC_HMAC_ALGORITHM) + "\"}"; // use HMAC otherwise, since it accepts anything
        }
    #endif

    // return whatever we're sending
    return "{\"ss\":\"" + enString_EscapeQuotes(source_script)
        + "\",\"ts\":\"" + enString_EscapeQuotes(target_script)
        + "\",\"m\":\"" + enString_EscapeQuotes(method)
        + "\"" + addl + "}";
}

integer _enRPC_Unmarshal(
    string source_prim,
    integer source_link,
    string json,
    integer int,
    string params
)
{
    #if defined TRACE_ENRPC_UNMARSHAL
        enLog_TraceParams(
            "_enRPC_Unmarshal",
            [
                "source_prim",
                "source_link",
                "json",
                "int",
                "params"
            ],
            [
                enPrim_Elem(source_prim),
                source_link,
                json,
                int,
                params
            ]
        );
    #endif

    if (llJsonValueType(json, []) != JSON_OBJECT) return -1; // always object

    string source_region;
    if (llJsonValueType(json, ["sr"]) != JSON_INVALID) source_region = llJsonGetValue(json, ["sr"]);
    string target_region;
    if (llJsonValueType(json, ["tr"]) != JSON_INVALID) target_region = llJsonGetValue(json, ["tr"]);

    // filter out messages that are targeted to other regions
    #if !defined FEATURE_ENRPC_ALLOW_ALL_TARGET_REGIONS
        if (target_region != "")
        {
            if (target_region != llGetRegionName()) return 1; // not targeted to this region
        }
    #endif

    string source_url;
    if (llJsonValueType(json, ["su"]) != JSON_INVALID) source_url = llJsonGetValue(json, ["su"]);

    if (llJsonValueType(json, ["sp"]) != JSON_INVALID) source_prim = llJsonGetValue(json, ["sp"]);

    string target_prim;
    if (llJsonValueType(json, ["tp"]) != JSON_INVALID) target_prim = llJsonGetValue(json, ["tp"]);

    // filter out messages that are targeted to other prims
    #if !defined FEATURE_ENRPC_ALLOW_ALL_TARGET_PRIMS
        if (target_prim != "")
        {
            if (target_prim != (string)llGetKey()) return 2; // not targeted to this prim
        }
    #endif

    string source_script = llJsonGetValue(json, ["ss"]);
    string target_script = llJsonGetValue(json, ["ts"]);

    // filter out messages that are targeted to other scripts
    #if defined OVERRIDE_ENRPC_ALLOWED_SOURCE_SCRIPTS
        if (llListFindList(OVERRIDE_ENRPC_ALLOWED_SOURCE_SCRIPTS, [source_script]) == -1) return 3; // not sent from an allowed source script
    #endif

    list allowed_targets = ["", llGetScriptName()]; // allow messages targeted to "" (all) and this script only
    #if defined OVERRIDE_ENRPC_ALLOWED_TARGET_SCRIPTS
        allowed_targets += OVERRIDE_ENRPC_ALLOWED_TARGET_SCRIPTS; // allow messages targeted to OVERRIDE_ENRPC_ALLOWED_TARGET_SCRIPTS list as well
    #endif
    #if !defined FEATURE_ENRPC_ALLOW_ALL_TARGET_SCRIPTS
    // filter out messages not targeted to a script in allowed_targets
        if (llListFindList(allowed_targets, [target_script]) == -1)
        {
    #endif
            #if !defined FEATURE_ENRPC_ALLOW_ALL_TARGET_SCRIPTS && defined FEATURE_ENRPC_ALLOW_FUZZY_TARGET_SCRIPT
                // using substring matching
                if (llSubStringIndex(llGetScriptName(), target_script) == -1) return 4; // not targeted to us
            #endif
            #if !defined FEATURE_ENRPC_ALLOW_ALL_TARGET_SCRIPTS && !defined FEATURE_ENRPC_ALLOW_FUZZY_TARGET_SCRIPT
                // using exact matching
                return 5; // not targeted to us
            #endif
    #if !defined FEATURE_ENRPC_ALLOW_ALL_TARGET_SCRIPTS
        }
    #endif

    string domain;
    if (llJsonValueType(json, ["d"]) != JSON_INVALID) domain = llJsonGetValue(json, ["d"]);

    if (llJsonValueType(json, ["i"]) != JSON_INVALID) int = (integer)llJsonGetValue(json, ["i"]);

    string method = llJsonGetValue(json, ["m"]);

    if (llJsonValueType(json, ["p"]) != JSON_INVALID) params = llJsonGetValue(json, ["p"]);

    string id;
    if (llJsonValueType(json, ["id"]) != JSON_INVALID) id = llJsonGetValue(json, ["id"]);

    string result = JSON_INVALID;
    if (llJsonValueType(json, ["r"]) != JSON_INVALID) result = llJsonGetValue(json, ["r"]);

    integer error_code;
    string error_message = JSON_INVALID;
    string error_data;
    if (llJsonValueType(json, ["e"]) != JSON_INVALID)
    {
        error_code = (integer)llJsonGetValue(json, ["e", "c"]);
        error_message = llJsonGetValue(json, ["e", "m"]);
    }
    if (llJsonValueType(json, ["e", "c"]) != JSON_INVALID) error_data = llJsonGetValue(json, ["e", "d"]);

    if (source_link != -1 && domain != OVERRIDE_ENRPC_DOMAIN) return 6; // discard message if it doesn't match the domain OVERRIDE_ENRPC_DOMAIN and received via link_message

    string key_name;

    #if defined FEATURE_ENRPC_ENABLE_VERIFICATION
        if (llJsonValueType(json, ["s"]) == JSON_OBJECT)
        {
            string algorithm = llJsonGetValue(json, ["s", "a"]);
            string timestamp = llJsonGetValue(json, ["s", "t"]);

            if (llAbs(enDatetime_TimestampDiffToSeconds(timestamp, llGetTimestamp())) < OVERRIDE_ENRPC_SIGNATURE_EXPIRY)
            {
                #define _ENRPC_INBOUND_SIGNATURE_MESSAGE \
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
                    + enString_If(source_link == -1, target_prim + source_region + target_region, "")

                string rsa = llJsonGetValue(json, ["s", "r"]);
                string hmac = llJsonGetValue(json, ["s", "h"]);

                #if defined TRACE_ENRPC_INBOUND_SIGNATURE_MESSAGE
                    enLog_Trace(_ENRPC_INBOUND_SIGNATURE_MESSAGE);
                #endif

                // iterate through all known keys until we find one that works
                integer valid;
                integer index;
                integer max = llGetListLength(ENRPC_KEYS) / 2;
                string use_key;
                do
                {
                    use_key = llList2String(ENRPC_KEYS, index * 2 + 1);
                    if (use_key != "")
                    {
                        // only attempt llVerifyRSA() if it looks like we're using an RSA public key, since it's slow
                        //string hmac = llJsonGetValue(json, ["s", "h"]);
                        if (rsa != JSON_INVALID) valid = llVerifyRSA(use_key, _ENRPC_INBOUND_SIGNATURE_MESSAGE, rsa, algorithm);
                        if (hmac != JSON_INVALID) valid = (llHMAC(use_key, _ENRPC_INBOUND_SIGNATURE_MESSAGE, algorithm) == hmac);
                    }
                }
                while (!valid && ++index < max);

                if (valid) key_name = llList2String(ENRPC_KEYS, (index - 1) * 2);
            }
        }
    #endif

    integer flags;
    string source_data;
    if (source_link == -1)
    {
        flags += FLAG_ENRPC_SOURCE_CLEP;
        source_data = "{\"r\":\"" + source_region + "\",\"p\":\"" + source_prim + "\"}";
    }
    else if (source_link == -2)
    {
        flags += FLAG_ENRPC_SOURCE_SNEP;
        source_data = "{\"u\":\"" + source_url + "\",\"p\":\"" + source_prim + "\"}";
    }
    else
    {
        flags += FLAG_ENRPC_SOURCE_LEP;
        source_data = "{\"l\":" + (string)source_link + "}";
    }

    if (result != JSON_INVALID) flags += FLAG_ENRPC_RESULT;
    if (error_message != JSON_INVALID) flags += FLAG_ENRPC_ERROR;
    if (~flags & (FLAG_ENRPC_RESULT | FLAG_ENRPC_ERROR)) flags += FLAG_ENRPC_REQUEST;

    #if defined EVENT_ENRPC_MESSAGE && defined TRACE_EVENT_ENRPC_MESSAGE
        enLog_TraceParams(
            "enrpc_message",
            [
                "flags",
                "key_name",
                "source_data",
                "source_script",
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
            ], [
                enInteger_ElemBitfield(flags),
                enString_Elem(key_name),
                source_data,
                enString_Elem(source_script),
                enString_Elem(target_script),
                enString_Elem(domain),
                int,
                enString_Elem(method),
                params,
                enString_Elem(id),
                result,
                error_code,
                enString_Elem(error_message),
                error_data
            ]
        );
    #endif
    #if defined EVENT_ENRPC_MESSAGE
        enrpc_message(
            flags,
            key_name,
            source_data,
            source_script,
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
        );
    #endif
    return 0;
}

/*!
Gets an enrolled key.
@param string key_name The identifer for this key.
@return string HMAC shared or RSA public key. WARNING: It's possible to leak HMAC shared keys if you are exposing RSA public keys and also use HMAC!
*/
string enRPC_GetKey(
    string key_name
)
{
    integer index = llListFindList(llList2ListSlice(ENRPC_KEYS, 0, -1, 2, 0), [key_name]);
    if (index == -1)
    {
        enLog_Warn("Key \"" + key_name + "\" not enrolled");
        return "";
    }
    return llList2String(ENRPC_KEYS, index * 2 + 1);
}
