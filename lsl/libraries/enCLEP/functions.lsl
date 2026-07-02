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


list _ENCLEP_HTTP_PARAMETERS;
list _ENCLEP_CLEP; // domain, flags, handle
#define _ENCLEP_CLEP_STRIDE 3
integer _ENCLEP_DIALOG_LSN; // used by enCLEP_DialogListen()
string _ENCLEP_SOURCE_REGION; // used by FEATURE_ENCLEP_STAGE_SOURCE_REGION
string _ENCLEP_SOURCE_PRIM; // used by FEATURE_ENCLEP_STAGE_SOURCE_PRIM

#if !defined OVERRIDE_ENCLEP_KEYS
    list ENRPC_KEYS; // only create an empty ENRPC_KEYS if OVERRIDE_ENCLEP_KEYS is not defined (and ENRPC_KEYS defined as global)
#endif

#if defined FEATURE_ENCLEP_STAGE_SOURCE_REGION
    enCLEP_StageSourceRegion(
        string source_region
    )
    {
        _ENCLEP_SOURCE_REGION = source_region;
    }
#endif

#if defined FEATURE_ENCLEP_STAGE_SOURCE_PRIM
    enCLEP_StageSourcePrim(
        string source_prim
    )
    {
        _ENCLEP_SOURCE_PRIM = source_prim;
    }
#endif

integer _enCLEP_link_message(
    integer l,
    integer i,
    string s,
    string k
)
{
    integer e = _enCLEP_Unmarshal(
        "", // source_prim
        l, // source_link
        s // json
    );

    #if defined TRACE_EVENT_ENCLEP_LINK_MESSAGE
        enLog_TraceParamsResult("_enCLEP_link_message", [
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
integer _enCLEP_listen(
    integer channel,
    string source_name,
    string source_prim,
    string s
)
{
    integer e = _enCLEP_Unmarshal(
        source_prim, // source_prim
        -1, // source_link
        s // json
    );
    
    #if defined TRACE_EVENT_ENCLEP_LISTEN
        enLog_TraceParamsResult(
            "_enCLEP_listen",
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
_enCLEP_uuid_changed(
    string last_uuid
)
{
    _enCLEP_UnListenAll();
    // are we listening to a self-domain?
    integer index = llListFindList(llList2ListSlice(_ENCLEP_CLEP, 0, -1, _ENCLEP_CLEP_STRIDE, 0), [last_uuid]);
    // if we are, replace it
    if (index != -1) _ENCLEP_CLEP = llListReplaceList(_ENCLEP_CLEP,
        [(string)llGetKey()],
        index * _ENCLEP_CLEP_STRIDE,
        index * _ENCLEP_CLEP_STRIDE);
    _enCLEP_ListenAll();
}

/*
enCLEP_DialogListen opens a regular llListen on a CLEP channel tied to this prim UUID and script name.
This can be used in conjunction with enCLEP_DialogChannel for a safe nearly-guaranteed-random channel for this script.
*/
enCLEP_DialogListen()
{
    _enCLEP_UnListenAll();
    if (_ENCLEP_DIALOG_LSN) llListenRemove(_ENCLEP_DIALOG_LSN);
    integer channel = enCLEP_DialogChannel();
    _ENCLEP_DIALOG_LSN = llListen(channel, "", (key)"", "");
    enLog_Trace("Dialog listening on channel " + (string)channel + " handle " + (string)_ENCLEP_DIALOG_LSN);
    _enCLEP_ListenAll();
}

/*
Removes the listen created by enCLEP_DialogListen.
*/
enCLEP_DialogListenRemove()
{
    if (!_ENCLEP_DIALOG_LSN) return;
    _enCLEP_UnListenAll();
    llListenRemove(_ENCLEP_DIALOG_LSN);
    _ENCLEP_DIALOG_LSN = 0;
    _enCLEP_ListenAll();
}

/*
Initializes or updates a dynamically managed CLEP listener.
This is like llListen, but easier to use.

enCLEP_Listen(...) will return 0 and fail to add the listen if you attempt to
add more than 65 listeners (the maximum allowed per script). If you call
llListen separately, set the number of listens you want reserved for non-CLEP\
use by adding the following line:
    #define OVERRIDE_INTEGER_ENCLEP_RESERVE_LISTENS x
where x is the number of listens you want to allocate for non-CLEP use.

Note: domains can be set as the local prim's UUID, in which case they will be
automatically refreshed on key or link change. However, this ONLY works if the
domain itself is just the UUID - no other data can be added.

WARNING: If the local prim's UUID is used as the domain, you MUST use the
state_entry, on_rez, and changed event handler include files, which will
dynamically update the domain after a key change. (This is done automatically
in event-handlers.lsl if you use it.)
*/
integer enCLEP_Listen(
    string domain,  // domain to listen to
    integer flags   // ENCLEP_LISTEN_* flags
)
{
    #if defined TRACE_ENCLEP_LISTEN
        enLog_TraceParams("enCLEP_Listen", ["domain", "flags"], [
            enString_Elem(domain),
            enInteger_ElemBitfield(flags)
            ]);
    #endif
    _enCLEP_UnListenAll();
    integer index = llListFindList(_ENCLEP_CLEP, [domain]);
    if (index == -1 && flags & FLAG_ENCLEP_LISTEN_REMOVE)
    { // nothing to remove, so return error
        _enCLEP_ListenAll();
        return __LINE__;
    }
    if (~index) _ENCLEP_CLEP = llDeleteSubList(_ENCLEP_CLEP, index, index + _ENCLEP_CLEP_STRIDE - 1); // index == -1; delete existing domain CLEP, so it can be cleanly appended to the end
    if (llGetListLength(_ENCLEP_CLEP) / _ENCLEP_CLEP_STRIDE + OVERRIDE_INTEGER_ENCLEP_RESERVE_LISTENS > 63)
    { // too many listens (maximum 65, so if we are currently at 64 or more, fail)
        _enCLEP_ListenAll();
        return __LINE__;
    }
    if (~flags & FLAG_ENCLEP_LISTEN_REMOVE) _ENCLEP_CLEP += [domain, flags, 0]; // add to _ENCLEP_CLEP only if we aren't removing it
    _enCLEP_ListenAll();
    return 0;
}

//  resets and removes all CLEP listeners, for single-purpose scripts to not have to independently keep track of listen handles
enCLEP_ListenReset()
{
    #if defined TRACE_ENCLEP_LISTENRESET
        enLog_TraceParams("enCLEP_ListenReset", [], []);
    #endif
    _enCLEP_UnListenAll();
    _ENCLEP_CLEP = [];
}

//  internal function that runs llListenRemove on everything in _ENCLEP_CLEP
_enCLEP_UnListenAll()
{
    #if defined TRACE_ENCLEP_UNLISTENALL
        enLog_TraceParams("enCLEP_UnListenAll", [], []);
    #endif
    integer i;
    integer l = llGetListLength(_ENCLEP_CLEP) / _ENCLEP_CLEP_STRIDE;
    for (i = 0; i < l; i++) llListenRemove((integer)llList2String(_ENCLEP_CLEP, i * _ENCLEP_CLEP_STRIDE + 2)); // for each domain in _ENCLEP_CLEP, remove listen by handle (we'll be replacing later)
}

//  internal function that runs llListen on everything in _ENCLEP_CLEP - DON'T run this without running _enCLEP_UnListenAll() first!
_enCLEP_ListenAll()
{
    #if defined TRACE_ENCLEP_LISTENALL
        enLog_TraceParams("enCLEP_ListenAll", [], []);
    #endif

    integer i;
    integer l = llGetListLength(_ENCLEP_CLEP) / _ENCLEP_CLEP_STRIDE;
    if (l > 64 - enCLEP_ReservedListens())
    {
        enLog_Warn("Listen overflow (" + (string)l + " + " + (string)enCLEP_ReservedListens() + " > 64)");
        l = 64 - enCLEP_ReservedListens();
    }
    list c;
    // for each domain in _ENCLEP_CLEP, add listen and update _ENCLEP_CLEP with handle
    for (i = 0; i < l; i++)
    {
        string domain = llList2String(_ENCLEP_CLEP, i * _ENCLEP_CLEP_STRIDE);
        integer channel = enCLEP_Channel(domain);
        c += [channel];
        integer handle = llListen(llList2Integer(c, -1), "", (key)"", "");
        _ENCLEP_CLEP = llListReplaceList(_ENCLEP_CLEP, [handle], i * _ENCLEP_CLEP_STRIDE + 2, i * _ENCLEP_CLEP_STRIDE + 2);
        enLog_Trace("Listening on CLEP domain \"" + domain + "\"");
    }
}

/*
note: enCLEP_GenerateRequest() and enCLEP_GenerateResult() were removed, just call _enCLEP_Send() directly
*/
string enCLEP_LinkMessageRequest(
    integer target_link,
    string target_script,
    string domain,
    list method,
    string id,
    string params
)
{
    return _enCLEP_Send(FLAG_ENCLEP_USE_LINK_MESSAGE, "", "", target_link, target_script, domain, method, id, params, "");
}

string enCLEP_LinkMessageResult(
    integer target_link,
    string target_script,
    string domain,
    list method,
    string id,
    string params,
    string result
)
{
    return _enCLEP_Send(FLAG_ENCLEP_USE_LINK_MESSAGE, "", "", target_link, target_script, domain, method, id, params, result);
}

string enCLEP_ChatRequest(
    string target_region,
    string target_prim,
    string target_script,
    string domain,
    list method,
    string id,
    string params
)
{
    return _enCLEP_Send(FLAG_ENCLEP_USE_LINK_MESSAGE, target_region, target_prim, 0, target_script, domain, method, id, params, "");
}

string enCLEP_ChatResult(
    string target_region,
    string target_prim,
    string target_script,
    string domain,
    list method,
    string id,
    string params,
    string result
)
{
    return _enCLEP_Send(FLAG_ENCLEP_USE_LINK_MESSAGE, target_region, target_prim, 0, target_script, domain, method, id, params, result);
}

/*
NOTE: in testing, a JSON-based RPC solution added ~6k of memory overhead for send/receive
this was switched back to a list-based method on 2026-01-15 to save that memory
then switched back to JSON on 2026-06-30 for slua compatibility
*/
string _enCLEP_Send(
    integer flags, // internal flags
    string target_region,
    string target_prim,
    integer target_link,
    string target_script,
    string domain,
    list method,
    string id,
    string params,
    string result // if error, error message
)
{
    string timestamp = llGetTimestamp();

    string target;
    if (flags & FLAG_ENCLEP_USE_LINK_MESSAGE)
    { // we are using link_message
        if (!target_link) target_link = OVERRIDE_INTEGER_ENCLEP_LINK_MESSAGE_SCOPE;
        target = llList2Json(JSON_OBJECT, ["link", target_link, "script", "\"" + enString_EscapeQuotes(target_script) + "\""]);
    }
    else
    { // we are using chat
        list targets;
        if (target_region != "") targets += ["region", target_region];
        if (target_prim != "") targets += ["prim", target_prim];
        if (target_script != "") targets += ["script", target_script];
        target = enList_ToJsonObject(targets);
    }
    if (id == "") id = llGenerateKey();
    list addl;
    if (params != "") addl += ["params", params];
    if (result != "") addl += ["result", result];

    string payload = llList2Json(JSON_OBJECT, [
        "source", enList_ToJsonObject([
            "region",
                #if defined FEATURE_ENCLEP_STAGE_SOURCE_REGION
                    enString_If(_ENCLEP_SOURCE_REGION == "", llGetRegionName(), _ENCLEP_SOURCE_REGION),
                #else
                    llGetRegionName(),
                #endif
            "prim", 
                #if defined FEATURE_ENCLEP_STAGE_SOURCE_PRIM
                    enString_If(_ENCLEP_SOURCE_PRIM == "", llGetKey(), _ENCLEP_SOURCE_PRIM),
                #else
                    llGetKey(),
                #endif
            "script",
            llGetScriptName()
        ]),
        "target", target,
        "domain", "\"" + enString_EscapeQuotes(domain) + "\"",
        "id", "\"" + enString_EscapeQuotes((string)id) + "\"",
        "method", llList2Json(JSON_ARRAY, method),
        "utime", llGetUnixTime()
    ] + addl);

    if (target_link)
    {
        #if (defined FEATURE_ENCLEP_USE_LINK_MESSAGE || defined FEATURE_ENCLEP_USE_LINK_MESSAGE_OUTBOUND)
            llMessageLinked(
                target_link,
                0,
                payload,
                ""
            );
        #else
            enLog_Error("FEATURE_ENCLEP_USE_LINK_MESSAGE[_OUTBOUND] not defined");
        #endif
    }
    else
    {
        #if (defined FEATURE_ENCLEP_USE_CHAT || defined FEATURE_ENCLEP_USE_CHAT_OUTBOUND)
            integer channel = enCLEP_Channel(domain);
            if (target_prim == "") target_prim = NULL_KEY;
            if (target_prim == NULL_KEY) llRegionSay(channel, payload); // RS if prim is not specified
            else if (llGetObjectDetails(target_prim, [OBJECT_PHANTOM]) != []) llRegionSayTo(target_prim, channel, payload); // RST if prim is in region
            else llShout(channel, payload); // shout if prim is specified but not in region
        #else
            enLog_Error("FEATURE_ENCLEP_USE_CHAT[_OUTBOUND] not defined");
        #endif
    }

    #if defined TRACE_ENCLEP_SEND
        enLog_TraceParams(
            "_enCLEP_Send",
            [
                "flags",
                "target", 
                "domain", 
                "method", 
                "id", 
                "params", 
                "result"
            ], 
            [
                enInteger_ElemBitfield(flags),
                target, 
                enString_Elem(domain), 
                llDumpList2String(method, "."),
                enString_Elem(id), 
                params, 
                result
            ]
        );
    #endif

    if (flags & FLAG_ENCLEP_RETURN) // return data directly from function instead of sending it
        return payload;

    return id;
}

integer _enCLEP_Unmarshal(
    string source_prim,
    integer source_link,
    string json
)
{
    #if defined TRACE_ENCLEP_UNMARSHAL
        enLog_TraceParams(
            "_enCLEP_Unmarshal",
            [
                "source_prim",
                "source_link",
                "json"
            ],
            [
                enPrim_Elem(source_prim),
                source_link,
                json
            ]
        );
    #endif

    if (llJsonGetValue(json, ["payload"]) != JSON_INVALID) json = llJsonGetValue(json, ["payload"]); // un-encapsulate payload

    #if !defined FEATURE_ENCLEP_ALLOW_ALL_TARGET_REGIONS
        // filter out messages that are targeted to other regions
        string target_region = llJsonGetValue(json, ["target", "region"]);
        if (llListFindList(["", JSON_INVALID, JSON_NULL], [target_region]) == -1)
        {
            if (target_region != llGetRegionName()) return 0x1; // not targeted to this region
        }
    #endif

    #if !defined FEATURE_ENCLEP_ALLOW_ALL_TARGET_PRIMS
        // filter out messages that are targeted to other prims
        string target_prim = llJsonGetValue(json, ["target", "prim"]);
        if (llListFindList(["", JSON_INVALID, JSON_NULL], [target_prim]) == -1)
        {
            if (target_prim != (string)llGetKey()) return 0x2; // not targeted to this prim
        }
    #endif

    // filter out messages that are sourced from scripts not in the allowed list
    #if defined OVERRIDE_ENCLEP_ALLOWED_SOURCE_SCRIPTS
        if (llListFindList(OVERRIDE_ENCLEP_ALLOWED_SOURCE_SCRIPTS, [llJsonGetValue(json, ["source", "script"])]) == -1) return 0x3; // not sent from an allowed source script
    #endif

    #if !defined FEATURE_ENCLEP_DISABLE_SOURCE_PRIM_VERIFICATION
        // filter out messages where the self-reported source_prim does not match the prim that sent this message
        // this breaks if a relay is used, so to accept messages from relays,
        // you must define FEATURE_ENCLEP_DISABLE_SOURCE_PRIM_VERIFICATION and forego this check
        if (source_prim != llJsonGetValue(json, ["source", "prim"])) return 0x4;
    #endif

    string target_script = llJsonGetValue(json, ["target", "script"]);

    list allowed_targets = ["", JSON_INVALID, JSON_NULL, llGetScriptName()]; // allow messages targeted to "" (all) and this script only
    #if defined OVERRIDE_ENCLEP_ALLOWED_TARGET_SCRIPTS
        allowed_targets += OVERRIDE_ENCLEP_ALLOWED_TARGET_SCRIPTS; // allow messages targeted to OVERRIDE_ENCLEP_ALLOWED_TARGET_SCRIPTS list as well
    #endif
    #if !defined FEATURE_ENCLEP_ALLOW_ALL_TARGET_SCRIPTS
    // filter out messages not targeted to a script in allowed_targets
        if (llListFindList(allowed_targets, [target_script]) == -1)
        {
    #endif
            #if !defined FEATURE_ENCLEP_ALLOW_ALL_TARGET_SCRIPTS && defined FEATURE_ENCLEP_ALLOW_FUZZY_TARGET_SCRIPT
                // using substring matching
                if (llSubStringIndex(llGetScriptName(), target_script) == -1) return 0x5; // not targeted to us
            #endif
            #if !defined FEATURE_ENCLEP_ALLOW_ALL_TARGET_SCRIPTS && !defined FEATURE_ENCLEP_ALLOW_FUZZY_TARGET_SCRIPT
                // using exact matching
                return 0x6; // not targeted to us
            #endif
    #if !defined FEATURE_ENCLEP_ALLOW_ALL_TARGET_SCRIPTS
        }
    #endif

    #if !defined FEATURE_ENCLEP_ALLOW_ALL_LINK_MESSAGE_DOMAINS
        if (source_link > -1 && llJsonGetValue(json, ["domain"]) != OVERRIDE_STRING_ENCLEP_LINK_MESSAGE_DOMAIN)
            return 0x7; // discard message if it doesn't match the domain OVERRIDE_STRING_ENCLEP_LINK_MESSAGE_DOMAIN and received via link_message
    #endif

    string domain = llJsonGetValue(json, ["domain"]);
    list method = llJson2List(llJsonGetValue(json, ["method"]));
    string params = llJsonGetValue(json, ["params"]);
    string id = llJsonGetValue(json, ["id"]);
    string result = llJsonGetValue(json, ["result"]);

    #if defined EVENT_ENCLEP_MESSAGE && defined TRACE_EVENT_ENCLEP_MESSAGE
        enLog_TraceParams(
            "enclep_message",
            [
                "domain",
                "method",
                "id",
                "params",
                "result"
            ],
            [
                enString_Elem(domain),
                llDumpList2String(method, "."),
                enString_Elem(id),
                params,
                result
            ]
        );
    #endif
    #if defined EVENT_ENCLEP_MESSAGE
        enclep_message(
            domain,
            method,
            id,
            params,
            result
        );
    #endif
    return 0;
}
