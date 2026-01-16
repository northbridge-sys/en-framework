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
        s // json
    );

    #if defined TRACE_EVENT_ENRPC_LINK_MESSAGE
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
        s // json
    );
    
    #if defined TRACE_EVENT_ENRPC_LISTEN
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
    #if defined TRACE_ENRPC_LISTEN
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
    #if defined TRACE_ENRPC_LISTENRESET
        enLog_TraceParams("enRPC_ListenReset", [], []);
    #endif
    _enRPC_UnListenAll();
    _ENRPC_CLEP = [];
}

//  internal function that runs llListenRemove on everything in _ENRPC_CLEP
_enRPC_UnListenAll()
{
    #if defined TRACE_ENRPC_UNLISTENALL
        enLog_TraceParams("enRPC_UnListenAll", [], []);
    #endif
    integer i;
    integer l = llGetListLength(_ENRPC_CLEP) / _ENRPC_CLEP_STRIDE;
    for (i = 0; i < l; i++) llListenRemove((integer)llList2String(_ENRPC_CLEP, i * _ENRPC_CLEP_STRIDE + 2)); // for each domain in _ENRPC_CLEP, remove listen by handle (we'll be replacing later)
}

//  internal function that runs llListen on everything in _ENRPC_CLEP - DON'T run this without running _enRPC_UnListenAll() first!
_enRPC_ListenAll()
{
    #if defined TRACE_ENRPC_LISTENALL
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

/*
NOTE: in testing, a JSON-based RPC solution added ~6k of memory overhead for send/receive
this was switched back to a list-based method on 2026-01-15 to save that memory
*/
string _enRPC_Send(
    integer flags, // internal flags
    string key_name,
    string source_script,
    string target_snep, // target_request_id (response to inbound HTTP request), target_url (request to general HTTP server), relay_url (request to SNEP relay)
    string target_region,
    string target_prim,
    string target_script,
    string domain,
    string method,
    string params,
    string id,
    string e, // "" for request, "0" for successful response, any non-zero integer for error
    string result // if error, error message
)
{
    string timestamp = llGetTimestamp();

    integer target_link;
    if (flags & FLAG_ENRPC_METHOD_LEP)
    {
        if ((integer)target_prim || target_prim == "0")
        { // the specified target_prim is actually target_link, so swap them
            target_link = (integer)target_prim;
            target_prim = llGetLinkKey(target_link);
        }
        if (!target_link) target_link = OVERRIDE_INTEGER_ENRPC_LINK_MESSAGE_SCOPE;
    }

    list data = [
        timestamp,
        enString_If(flags & FLAG_ENRPC_METHOD_CLEP, llGetRegionName(), ""),
        llGetKey(),
        source_script,
        llReplaceSubString(target_snep, "\n", "", 0),
        enString_If(flags & FLAG_ENRPC_METHOD_CLEP, target_region, ""),
        target_prim,
        target_script,
        llReplaceSubString(domain, "\n", "", 0),
        llReplaceSubString(method, "\n", "", 0),
        llEscapeURL(params),
        llReplaceSubString(id, "\n", "", 0),
        llReplaceSubString(e, "\n", "", 0),
        llEscapeURL(result)
    ];

    #if defined FEATURE_ENRPC_ENABLE_SIGNING
        // signing is enabled - are we signing this message?
        string private_key = enRPC_GetKey(key_name); // import private_key from ENRPC_KEYS

        if (private_key != "")
        {
            string timestamp = llGetTimestamp();

            if (llGetSubString(private_key, 0, 4) == "-----") // RSA private key provided
                data += [
                    "RSA",
                    OVERRIDE_STRING_ENRPC_RSA_ALGORITHM,
                    llSignRSA(private_key, llDumpList2String(data, "\n"), OVERRIDE_STRING_ENRPC_RSA_ALGORITHM)
                ];
            else // HMAC shared key provided
                data += [
                    "HMAC",
                    OVERRIDE_STRING_ENRPC_HMAC_ALGORITHM,
                    llHMAC(private_key, llDumpList2String(data, "\n"), OVERRIDE_STRING_ENRPC_RSA_ALGORITHM)
                ];
        }
    #endif

    #if defined FEATURE_ENRPC_ENABLE_LEP
        if (flags & FLAG_ENRPC_METHOD_LEP)
        {
            llMessageLinked(
                target_link,
                0,
                llDumpList2String(data, "\n"),
                ""
            );
        }
    #endif

    #if defined FEATURE_ENRPC_ENABLE_CLEP
        if (flags & FLAG_ENRPC_METHOD_CLEP)
        {
            integer channel = enRPC_Channel(domain);
            if (target_prim == "") target_prim = NULL_KEY;
            if (target_prim == NULL_KEY) llRegionSay(channel, llDumpList2String(data, "\n")); // RS if prim is not specified
            else if (llGetObjectDetails(target_prim, [OBJECT_PHANTOM]) != []) llRegionSayTo(target_prim, channel, llDumpList2String(data, "\n")); // RST if prim is in region
    #endif
    #if defined FEATURE_ENRPC_ENABLE_CLEP && defined FEATURE_ENCLEP_ENABLE_SHOUT
            else llShout(channel, llDumpList2String(data, "\n")); // shout if prim is not in region and FEATURE_ENCLEP_ENABLE_SHOUT is defined
    #elif defined FEATURE_ENRPC_ENABLE_CLEP && defined FEATURE_ENCLEP_ENABLE_SAY
            else llSay(channel, llDumpList2String(data, "\n")); // say if prim is not in region and FEATURE_ENCLEP_ENABLE_SAY is defined
    #elif defined FEATURE_ENRPC_ENABLE_CLEP && defined FEATURE_ENCLEP_ENABLE_WHISPER
            else llWhisper(channel, llDumpList2String(data, "\n")); // whisper if prim is not in region and FEATURE_ENCLEP_ENABLE_WHISPER is defined
    #endif
    #if defined FEATURE_ENRPC_ENABLE_CLEP
        }
    #endif

    #if defined FEATURE_ENRPC_ENABLE_SNEP
        if (flags & FLAG_ENRPC_METHOD_SNEP)
        {
            if (enKey_IsNotNull(target_snep))
            { // target_snep is a UUID; we are responding to a previous inbound HTTP request
                llHTTPResponse(
                    target_snep, // pass target_snep as request ID
                    200,
                    llDumpList2String(data, "\n")
                );
            }
            else
            {
                // target_snep is probably a URL; we are requesting via a new outbound HTTP request
                id = llHTTPRequest(
                    target_snep,
                    _ENRPC_HTTP_PARAMETERS,
                    llDumpList2String(data, "\n")
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
    string s_data
)
{
    #if defined TRACE_ENRPC_UNMARSHAL
        enLog_TraceParams(
            "_enRPC_Unmarshal",
            [
                "source_prim",
                "source_link",
                "s_data"
            ],
            [
                enPrim_Elem(source_prim),
                source_link,
                s_data
            ]
        );
    #endif

    list data = llParseStringKeepNulls(s_data, ["\n"], []);

    // unescape llEscapeURL-ed elements
    data = llListReplaceList(data, [llUnescapeURL(llList2String(data, CONST_ENRPC_DATA_PARAMS))], CONST_ENRPC_DATA_PARAMS, CONST_ENRPC_DATA_PARAMS);
    data = llListReplaceList(data, [llUnescapeURL(llList2String(data, CONST_ENRPC_DATA_RESULT))], CONST_ENRPC_DATA_RESULT, CONST_ENRPC_DATA_RESULT);

    #if !defined FEATURE_ENRPC_ALLOW_ALL_TARGET_REGIONS
        // filter out messages that are targeted to other regions
        string target_region = llList2String(data, CONST_ENRPC_DATA_TARGET_REGION);
        if (target_region != "")
        {
            if (target_region != llGetRegionName()) return 0x1; // not targeted to this region
        }
    #endif

    #if !defined FEATURE_ENRPC_ALLOW_ALL_TARGET_PRIMS
        // filter out messages that are targeted to other prims
        string target_prim = llList2String(data, CONST_ENRPC_DATA_TARGET_PRIM);
        if (target_prim != "")
        {
            if (target_prim != (string)llGetKey()) return 0x2; // not targeted to this prim
        }
    #endif

    // filter out messages that are targeted to other scripts
    #if defined OVERRIDE_ENRPC_ALLOWED_SOURCE_SCRIPTS
        if (llListFindList(OVERRIDE_ENRPC_ALLOWED_SOURCE_SCRIPTS, [llList2String(data, CONST_ENRPC_DATA_SOURCE_SCRIPT)]) == -1) return 0x3; // not sent from an allowed source script
    #endif

    string target_script = llList2String(data, CONST_ENRPC_DATA_TARGET_SCRIPT);

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
                if (llSubStringIndex(llGetScriptName(), target_script) == -1) return 0x4; // not targeted to us
            #endif
            #if !defined FEATURE_ENRPC_ALLOW_ALL_TARGET_SCRIPTS && !defined FEATURE_ENRPC_ALLOW_FUZZY_TARGET_SCRIPT
                // using exact matching
                return 0x5; // not targeted to us
            #endif
    #if !defined FEATURE_ENRPC_ALLOW_ALL_TARGET_SCRIPTS
        }
    #endif

    if (source_link != -1 && llList2String(data, CONST_ENRPC_DATA_DOMAIN) != OVERRIDE_STRING_ENRPC_LEP_DOMAIN) return 0x6; // discard message if it doesn't match the domain OVERRIDE_STRING_ENRPC_LEP_DOMAIN and received via link_message

    string key_name;

    #if defined FEATURE_ENRPC_ENABLE_VERIFICATION
        string signature_method = llList2String(data, CONST_ENRPC_DATA_SIGNATURE_METHOD);
        if (signature_method == "RSA" || signature_method == "HMAC")
        {
            string timestamp = llList2String(data, CONST_ENRPC_DATA_TIMESTAMP);

            if (llAbs(enDatetime_TimestampDiffToSeconds(timestamp, llGetTimestamp())) < OVERRIDE_INTEGER_ENRPC_SIGNATURE_EXPIRY)
            {
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
                        if (signature_method == "RSA") valid = llVerifyRSA(use_key, llDumpList2String(llList2List(data, 0, CONST_ENRPC_DATA_SIGNATURE_METHOD - 1), "\n"), llList2String(data, CONST_ENRPC_DATA_SIGNATURE_HASH), llList2String(data, CONST_ENRPC_DATA_SIGNATURE_ALGORITHM));
                        else valid = (llHMAC(use_key, llDumpList2String(llList2List(data, 0, CONST_ENRPC_DATA_SIGNATURE_METHOD - 1), "\n"), llList2String(data, CONST_ENRPC_DATA_SIGNATURE_ALGORITHM)) == llList2String(data, CONST_ENRPC_DATA_SIGNATURE_HASH));
                    }
                }
                while (!valid && ++index < max);

                if (valid) key_name = llList2String(ENRPC_KEYS, (index - 1) * 2);
            }
        }
    #endif

    integer flags;
    if (source_link == -1) flags += FLAG_ENRPC_METHOD_CLEP;
    else if (source_link == -2) flags += FLAG_ENRPC_METHOD_SNEP;
    else flags += FLAG_ENRPC_METHOD_LEP;

    string e = llList2String(data, CONST_ENRPC_DATA_E);
    if (e == "") flags += FLAG_ENRPC_REQUEST;
    else if (!(integer)e) flags += FLAG_ENRPC_RESULT;
    else flags += FLAG_ENRPC_ERROR;

    #if defined EVENT_ENRPC_MESSAGE && defined TRACE_EVENT_ENRPC_MESSAGE
        enLog_TraceParams(
            "enrpc_message",
            [
                "flags",
                "key_name",
                "data"
            ],
            [
                enInteger_ElemBitfield(flags),
                enString_Elem(key_name),
                enList_Elem(data)
            ]
        );
    #endif
    #if defined EVENT_ENRPC_MESSAGE
        enrpc_message(
            flags,
            key_name,
            data
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
