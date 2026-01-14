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


/*!
An external loader for HTTP parameters is needed to simplify _enRPC_Send(), since lists don't work with the preprocessor.
*/
enRPC_StageHTTPParameters(
    list http_parameters
)
{
    _ENRPC_HTTP_PARAMETERS = http_parameters;
}

integer _enRPC_link_message(
    integer l,
    integer i,
    string s,
    string k
)
{
    integer e = _enRPC_Unmarshal(
        "", // source_prim
        l, // source_link
        s, // json
        i, // int (used only if not in json)
        k // params (used only if not in json)
    );

    #if defined TRACE_ENRPC_LINK_MESSAGE
        enLog_TraceParamsResult("_enRPC_link_message", [
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

/*
Process incoming listen event to see if it is a CLEP message.
If not, return a positive integer.
If so, check that the message is acceptable (matches a listened-to domain, ownership checks, etc.)
If the message is acceptable, route it appropriately (either to enLEP, or whatever other library or protocol) and return 0.
If not, return 0 to signal a CLEP message even if it wasn't routable.
*/
integer _enRPC_listen(
    integer channel,
    string source_name,
    string source_prim,
    string s
)
{
    integer e = _enRPC_Unmarshal(
        source_prim, // source_prim
        -1, // source_link
        s, // json
        0, // int (used only if not in json)
        "" // params (used only if not in json)
    );
    
    #if defined TRACE_ENCLEP_LISTEN
        enLog_TraceParamsResult(
            "_enRPC_listen",
            [
                "channel",
                "source_name",
                "source_prim",
                "s"
            ], [
                channel,
                enString_Elem(source_name),
                enString_Elem(source_prim),
                enString_Elem(s)
            ],
            (string)e
        );
    #endif

    return e;
}

//  internal function that runs after key change to reset any listens based on previous UUID
_enRPC_uuid_changed(
    string last_uuid
)
{
    _enRPC_UnListenAll();
    // are we listening to a self-domain?
    integer index = llListFindList(llList2ListSlice(_ENRPC_CLEP, 0, -1, _ENRPC_CLEP_STRIDE, 0), [last_uuid]);
    // if we are, replace it
    if (index != -1) _ENRPC_CLEP = llListReplaceList(_ENRPC_CLEP,
        [(string)llGetKey()],
        index * _ENRPC_CLEP_STRIDE,
        index * _ENRPC_CLEP_STRIDE);
    _enRPC_ListenAll();
}

/*
enRPC_DialogListen opens a regular llListen on a CLEP channel tied to this prim UUID and script name.
This can be used in conjunction with enRPC_DialogChannel for a safe nearly-guaranteed-random channel for this script.
*/
enRPC_DialogListen()
{
    _enRPC_UnListenAll();
    if (_ENRPC_DIALOG_LSN) llListenRemove(_ENRPC_DIALOG_LSN);
    integer channel = enRPC_DialogChannel();
    _ENRPC_DIALOG_LSN = llListen(channel, "", "", "");
    enLog_Trace("Dialog listening on channel " + (string)channel + " handle " + (string)_ENRPC_DIALOG_LSN);
    _enRPC_ListenAll();
}

/*
Removes the listen created by enRPC_DialogListen.
*/
enRPC_DialogListenRemove()
{
    if (!_ENRPC_DIALOG_LSN) return;
    _enRPC_UnListenAll();
    llListenRemove(_ENRPC_DIALOG_LSN);
    _ENRPC_DIALOG_LSN = 0;
    _enRPC_ListenAll();
}

/*
Initializes or updates a dynamically managed CLEP listener.
This is like llListen, but easier to use.

enRPC_Listen(...) will return 0 and fail to add the listen if you attempt to
add more than 65 listeners (the maximum allowed per script). If you call
llListen separately, set the number of listens you want reserved for non-CLEP\
use by adding the following line:
    #define OVERRIDE_INTEGER_ENRPC_RESERVE_LISTENS x
where x is the number of listens you want to allocate for non-CLEP use.

Note: domains can be set as the local prim's UUID, in which case they will be
automatically refreshed on key or link change. However, this ONLY works if the
domain itself is just the UUID - no other data can be added.

WARNING: If the local prim's UUID is used as the domain, you MUST use the
state_entry, on_rez, and changed event handler include files, which will
dynamically update the domain after a key change. (This is done automatically
in event-handlers.lsl if you use it.)
*/
integer enRPC_Listen(
    string domain,  // domain to listen to
    integer flags   // ENCLEP_LISTEN_* flags
)
{
    #if defined TRACE_ENCLEP
        enLog_TraceParams("enRPC_Listen", ["domain", "flags"], [
            enString_Elem(domain),
            enInteger_ElemBitfield(flags)
            ]);
    #endif
    _enRPC_UnListenAll();
    integer index = llListFindList(_ENRPC_CLEP, [domain]);
    if (index == -1 && flags & FLAG_ENRPC_LISTEN_REMOVE)
    { // nothing to remove, so return error
        _enRPC_ListenAll();
        return __LINE__;
    }
    if (~index) _ENRPC_CLEP = llDeleteSubList(_ENRPC_CLEP, index, index + _ENRPC_CLEP_STRIDE - 1); // index == -1; delete existing domain CLEP, so it can be cleanly appended to the end
    if (llGetListLength(_ENRPC_CLEP) / _ENRPC_CLEP_STRIDE + OVERRIDE_INTEGER_ENRPC_RESERVE_LISTENS > 63)
    { // too many listens (maximum 65, so if we are currently at 64 or more, fail)
        _enRPC_ListenAll();
        return __LINE__;
    }
    if (~flags & FLAG_ENRPC_LISTEN_REMOVE) _ENRPC_CLEP += [domain, flags, 0]; // add to _ENRPC_CLEP only if we aren't removing it
    _enRPC_ListenAll();
    return 0;
}

//  resets and removes all CLEP listeners, for single-purpose scripts to not have to independently keep track of listen handles
enRPC_ListenReset()
{
    #if defined TRACE_ENCLEP
        enLog_TraceParams("enRPC_ListenReset", [], []);
    #endif
    _enRPC_UnListenAll();
    _ENRPC_CLEP = [];
}

//  internal function that runs llListenRemove on everything in _ENRPC_CLEP
_enRPC_UnListenAll()
{
    #if defined TRACE_ENCLEP
        enLog_TraceParams("enRPC_UnListenAll", [], []);
    #endif
    integer i;
    integer l = llGetListLength(_ENRPC_CLEP) / _ENRPC_CLEP_STRIDE;
    for (i = 0; i < l; i++) llListenRemove((integer)llList2String(_ENRPC_CLEP, i * _ENRPC_CLEP_STRIDE + 2)); // for each domain in _ENRPC_CLEP, remove listen by handle (we'll be replacing later)
}

//  internal function that runs llListen on everything in _ENRPC_CLEP - DON'T run this without running _enRPC_UnListenAll() first!
_enRPC_ListenAll()
{
    #if defined TRACE_ENCLEP
        enLog_TraceParams("enRPC_ListenAll", [], []);
    #endif

    integer i;
    integer l = llGetListLength(_ENRPC_CLEP) / _ENRPC_CLEP_STRIDE;
    if (l > 64 - enRPC_ReservedListens())
    {
        enLog_Warn("Listen overflow (" + (string)l + " + " + (string)enRPC_ReservedListens() + " > 64)");
        l = 64 - enRPC_ReservedListens();
    }
    list c;
    // for each domain in _ENRPC_CLEP, add listen and update _ENRPC_CLEP with handle
    for (i = 0; i < l; i++)
    {
        string domain = llList2String(_ENRPC_CLEP, i * _ENRPC_CLEP_STRIDE);
        integer channel = enRPC_Channel(domain);
        c += [channel];
        integer handle = llListen(llList2Integer(c, -1), "", "", "");
        llListReplaceList(_ENRPC_CLEP, [handle], i * _ENRPC_CLEP_STRIDE + 2, i * _ENRPC_CLEP_STRIDE + 2);
        enLog_Trace("Listening on CLEP domain \"" + domain + "\"");
    }
}

string _enRPC_Send(
    integer flags, // internal flags
    string key_name,
    string source_script,
    string target_selector, // LEP: target_link_number / CLEP: target_region (for routing only) / SNEP: target_request_id (response to inbound HTTP request), target_url (request to general HTTP server), relay_url (request to SNEP relay)
    string target_prim, // LEP: ignored / CLEP: target_prim (optional) / SNEP: target_prim (for SNEP relays only)
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
    string json;
    if (~flags & FLAG_ENRPC_METHOD_LEP) json += ",\"i\":" + (string)int; // embed int into JSON (used by CLEP/SNEP)
    if (domain != "") json += ",\"d\":\"" + enString_EscapeQuotes(domain) + "\""; // add domain
    if (id != "") json += ",\"id\":\"" + enString_EscapeQuotes(id) + "\""; // add id
    if (~flags & FLAG_ENRPC_METHOD_LEP && llJsonValueType(params, []) != JSON_INVALID) json += ",\"p\":" + params; // embed params into JSON (used by CLEP/SNEP)
    if (llJsonValueType(result, []) != JSON_INVALID) json += ",\"r\":" + result; // we are sending a response with a result, so add it
    else if (error_code || error_message != "" || error_data != "")
    { // we are sending a response with an error, so add it
        json += ",\"e\":{\"c\":" + (string)error_code + ",\"m\":\"" + enString_EscapeQuotes(error_message) + "\"";
        if (llJsonValueType(error_data, []) != JSON_INVALID) json += ",\"d\":" + error_data;
        json += "}";
    }
    // if no r/e, we are sending a request

    // what does target_selector do?
    // TODO: if target_prim is specified and valid within linkset, opportunistically send via CLEP if it is enabled
    // TODO: allow multi-method sending
    integer target_link;
    string target_region;
    string target_url;
    if (flags & FLAG_ENRPC_METHOD_LEP)
    {
        if (flags & (FLAG_ENRPC_METHOD_CLEP | FLAG_ENRPC_METHOD_SNEP)) return "";
        target_link = (integer)target_selector;
        if (!target_link) target_link = OVERRIDE_INTEGER_ENRPC_LINK_MESSAGE_SCOPE;
    }
    if (flags & FLAG_ENRPC_METHOD_CLEP)
    {
        if (flags & (FLAG_ENRPC_METHOD_LEP | FLAG_ENRPC_METHOD_CLEP)) return "";
        target_region = target_selector;
    }
    if (flags & FLAG_ENRPC_METHOD_SNEP)
    {
        if (flags & (FLAG_ENRPC_METHOD_CLEP | FLAG_ENRPC_METHOD_LEP)) return "";
        target_url = target_selector;
    }

    #if defined FEATURE_ENCLEP_ENABLE_ROUTING || defined FEATURE_ENRPC_ENABLE_SIGNING
        if (enKey_IsNotNull(target_prim)) // we are requesting routing, so add routing information
            json += ",\"sp\":\"" + (string)llGetKey() + "\",\"tp\":\"" + target_prim + "\",\"sr\":\"" + enString_EscapeQuotes(llGetRegionName()) + "\",\"tr\":\"" + enString_EscapeQuotes(target_region) + "\"";
        else if (key_name != "") // we are not requesting routing, but we are signing
            json += ",\"sp\":\"" + (string)llGetKey() + "\"";
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
                target_prim     \
                source_region    > these three values are only included if we are requesting routing
                target_selector /
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
                + enString_If(enKey_IsNotNull(target_prim), target_prim + llGetRegionName() + target_selector, "")

            #if defined TRACE_ENRPC_OUTBOUND_SIGNATURE_MESSAGE
                enLog_Trace(_ENRPC_OUTBOUND_SIGNATURE_MESSAGE);
            #endif
            
            if (llGetSubString(private_key, 0, 4) == "-----") json += ",\"s\":{\"a\":\"" + OVERRIDE_STRING_ENRPC_RSA_ALGORITHM + "\",\"t\":\"" + timestamp + "\",\"r\":\"" + llSignRSA(private_key, OVERRIDE_STRING_ENRPC_RSA_ALGORITHM + _ENRPC_OUTBOUND_SIGNATURE_MESSAGE, OVERRIDE_STRING_ENRPC_RSA_ALGORITHM) + "\"}"; // use RSA if we were passed an RSA private key
            else json += ",\"s\":{\"a\":\"" + OVERRIDE_STRING_ENRPC_HMAC_ALGORITHM + "\",\"t\":\"" + timestamp + "\",\"h\":\"" + llHMAC(private_key, OVERRIDE_STRING_ENRPC_HMAC_ALGORITHM + _ENRPC_OUTBOUND_SIGNATURE_MESSAGE, OVERRIDE_STRING_ENRPC_HMAC_ALGORITHM) + "\"}"; // use HMAC otherwise, since it accepts anything
        }
    #endif

    // add required values
    json = "{\"ss\":\"" + enString_EscapeQuotes(source_script)
        + "\",\"ts\":\"" + enString_EscapeQuotes(target_script)
        + "\",\"m\":\"" + enString_EscapeQuotes(method)
        + "\"" + json + "}";

    #if defined FEATURE_ENRPC_ENABLE_LEP
        if (flags & FLAG_ENRPC_METHOD_LEP)
        {
            llMessageLinked(
                target_link,
                int,
                _enRPC_Send(
                    0, // flags
                    key_name,
                    llGetScriptName(),
                    "", // target_region
                    "", // target_prim
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
                ),
                params
            );
        }
    #endif

    #if defined FEATURE_ENRPC_ENABLE_CLEP
        if (flags & FLAG_ENRPC_METHOD_CLEP)
        {
            integer channel = enRPC_Channel(domain);
            if (target_prim == "") target_prim = NULL_KEY;
            if (target_prim == NULL_KEY) llRegionSay(channel, json); // RS if prim is not specified
            else if (llGetObjectDetails(target_prim, [OBJECT_PHANTOM]) != []) llRegionSayTo(target_prim, channel, json); // RST if prim is in region
    #endif
    #if defined FEATURE_ENRPC_ENABLE_CLEP && defined FEATURE_ENCLEP_ENABLE_SHOUT
            else llShout(channel, json); // shout if prim is not in region and FEATURE_ENCLEP_ENABLE_SHOUT is defined
    #elif defined FEATURE_ENRPC_ENABLE_CLEP && defined FEATURE_ENCLEP_ENABLE_SAY
            else llSay(channel, json); // say if prim is not in region and FEATURE_ENCLEP_ENABLE_SAY is defined
    #elif defined FEATURE_ENRPC_ENABLE_CLEP && defined FEATURE_ENCLEP_ENABLE_WHISPER
            else llWhisper(channel, json); // whisper if prim is not in region and FEATURE_ENCLEP_ENABLE_WHISPER is defined
    #endif
    #if defined FEATURE_ENRPC_ENABLE_CLEP
        }
    #endif

    #if defined FEATURE_ENRPC_ENABLE_SNEP
        if (flags & FLAG_ENRPC_METHOD_SNEP)
        {
            if (enKey_IsNotNull(target_url))
            { // target_url is a UUID; we are responding to a previous inbound HTTP request
                llHTTPResponse(
                    target_url, // pass target_url as request ID
                    200,
                    json
                );
            }
            else
            {
                // target_url is probably a URL; we are requesting via a new outbound HTTP request
                id = llHTTPRequest(
                    target_url, 
                    _ENRPC_HTTP_PARAMETERS, 
                    json
                );
                _ENRPC_HTTP_PARAMETERS = [];
            }
        }
    #endif

    return id;
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

    string source_region = enString_JsonTryValue(json, ["sr"]);
    string target_region = enString_JsonTryValue(json, ["tr"]);

    // filter out messages that are targeted to other regions
    #if !defined FEATURE_ENRPC_ALLOW_ALL_TARGET_REGIONS
        if (target_region != "")
        {
            if (target_region != llGetRegionName()) return 1; // not targeted to this region
        }
    #endif

    string source_url = enString_JsonTryValue(json, ["su"]);
    source_prim = enString_JsonTryValueFallback(json, ["sp"], source_prim);

    string target_prim = enString_JsonTryValue(json, ["tp"]);

    // filter out messages that are targeted to other prims
    #if !defined FEATURE_ENRPC_ALLOW_ALL_TARGET_PRIMS
        if (target_prim != "")
        {
            if (target_prim != (string)llGetKey()) return 2; // not targeted to this prim
        }
    #endif

    string source_script = enString_JsonTryValue(json, ["ss"]);
    string target_script = enString_JsonTryValue(json, ["ts"]);

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

    string domain = enString_JsonTryValue(json, ["d"]);

    int = (integer)enString_JsonTryValueFallback(json, ["i"], (string)int);

    string method = enString_JsonTryValue(json, ["m"]);

    params = enString_JsonTryValueFallback(json, ["p"], params);

    string id = enString_JsonTryValue(json, ["id"]);

    string result = llJsonValueType(json, ["r"]); // this should be JSON_INVALID if no result

    integer error_code = (integer)enString_JsonTryValue(json, ["e", "c"]);
    string error_message = enString_JsonTryValue(json, ["e", "m"]);
    string error_data = enString_JsonTryValue(json, ["e", "d"]);

    if (source_link != -1 && domain != OVERRIDE_STRING_ENRPC_LEP_DOMAIN) return 6; // discard message if it doesn't match the domain OVERRIDE_STRING_ENRPC_LEP_DOMAIN and received via link_message

    string key_name;

    #if defined FEATURE_ENRPC_ENABLE_VERIFICATION
        if (llJsonValueType(json, ["s"]) == JSON_OBJECT)
        {
            string algorithm = llJsonGetValue(json, ["s", "a"]);
            string timestamp = llJsonGetValue(json, ["s", "t"]);

            if (llAbs(enDatetime_TimestampDiffToSeconds(timestamp, llGetTimestamp())) < OVERRIDE_INTEGER_ENRPC_SIGNATURE_EXPIRY)
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
        flags += FLAG_ENRPC_METHOD_CLEP;
        source_data = "{\"r\":\"" + source_region + "\",\"p\":\"" + source_prim + "\"}";
    }
    else if (source_link == -2)
    {
        flags += FLAG_ENRPC_METHOD_SNEP;
        source_data = "{\"u\":\"" + source_url + "\",\"p\":\"" + source_prim + "\"}";
    }
    else
    {
        flags += FLAG_ENRPC_METHOD_LEP;
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
