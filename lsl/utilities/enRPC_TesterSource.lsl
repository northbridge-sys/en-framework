#define EVENT_EN_STATE_ENTRY
#define EVENT_ENRPC_MESSAGE

//#define FEATURE_ENRPC_PROTOCOL_ROUTING
#define FEATURE_ENRPC_PROTOCOL_CLEP
#define FEATURE_ENRPC_PROTOCOL_LEP
//#define FEATURE_ENRPC_PROTOCOL_SIGNING
//#define FEATURE_ENRPC_SIGNATURE_VERIFICATION

#define OVERRIDE_STRING_ENRPC_LEP_DOMAIN "CLEP Test Domain"

#include "northbridge-sys/en-framework/lsl/libraries.lsl"

list ENRPC_KEYS = [
    "sample-rpc", "foobar"
];

string TESTER_KEY_NAME = "sample-rpc";
integer TESTER_LINK_NUM = LINK_THIS;
string TESTER_TARGET_SCRIPT = "";

en_state_entry()
{
    #if !defined FEATURE_ENRPC_PROTOCOL_SIGNING && !defined FEATURE_ENRPC_SIGNATURE_VERIFICATION
        TESTER_KEY_NAME = ""; // use a blank TESTER_KEY_NAME if signing is disabled, otherwise the messages will be dropped
    #endif

    enRPC_Listen(OVERRIDE_STRING_ENRPC_LEP_DOMAIN, FLAG_ENRPC_LISTEN_OWNERONLY);
    
    // return id can be stored for reference later if you want
    string id = enRPC_HybridRequestSigned(
        TESTER_KEY_NAME, // key_name
        "", // target_region
        "", // target_prim
        TESTER_TARGET_SCRIPT, // target_script
        OVERRIDE_STRING_ENRPC_LEP_DOMAIN, // domain - we use the LEP domain for convenience here
        "ping", // method
        "{\"start\":\"" + llGetTimestamp() + "\"}", // params
        llGenerateKey() // id
    );
    
    enLog_Info("Sent hybrid ping with ID \"" + id + "\" using key \"" + TESTER_KEY_NAME + "\"");
}

enrpc_message(
    integer flags,
    string key_name,
    integer source_link,
    list data
)
{
    if (~flags & FLAG_ENRPC_TYPE_RESULT) return;

    if (key_name != TESTER_KEY_NAME) return; // reject unsigned/missigned messages

    string method = llList2String(data, CONST_ENRPC_DATA_METHOD);
    if (llList2String(data, CONST_ENRPC_DATA_METHOD) != "ping") return; // only respond if method is "ping"

    string domain = llList2String(data, CONST_ENRPC_DATA_DOMAIN);
    string source_region = llList2String(data, CONST_ENRPC_DATA_SOURCE_REGION);
    string source_script = llList2String(data, CONST_ENRPC_DATA_SOURCE_SCRIPT);
    string id = llList2String(data, CONST_ENRPC_DATA_ID);
    string params = llList2String(data, CONST_ENRPC_DATA_PARAMS);
    string result = llList2String(data, CONST_ENRPC_DATA_RESULT);

    // convert timestamps into arbitrary millisecond-accurate integers, then get the differences between them for benchmarking
    integer start = enDatetime_TimestampToMillisec(llJsonGetValue(params, ["start"])); // params is a timestamp string
    integer mid = enDatetime_TimestampToMillisec(llJsonGetValue(result, ["mid"])); // result is a timestamp string
    integer end = enDatetime_NowToMillisec();
    
    enLog_Success("Got " + llList2String(["LEP", "CLEP", "SNEP"], llListFindList([FLAG_ENRPC_PROTOCOL_LEP, FLAG_ENRPC_PROTOCOL_CLEP, FLAG_ENRPC_PROTOCOL_SNEP], [flags & (FLAG_ENRPC_PROTOCOL_LEP | FLAG_ENRPC_PROTOCOL_CLEP | FLAG_ENRPC_PROTOCOL_SNEP)])) + " ping result for ID \"" + id + "\" (" + (string)enDatetime_AddMillisec(mid, -start) + "ms for request, " + (string)enDatetime_AddMillisec(end, -mid) + "ms for result) using key \"" + key_name + "\"");
}

default
{
    #include "northbridge-sys/en-framework/lsl/event-handlers.lsl"
}
