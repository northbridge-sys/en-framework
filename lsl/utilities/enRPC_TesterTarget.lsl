#define EVENT_EN_STATE_ENTRY
#define EVENT_ENRPC_MESSAGE

//#define FEATURE_ENCLEP_PROTOCOL_ROUTING
#define FEATURE_ENCLEP_PROTOCOL_CLEP
#define FEATURE_ENCLEP_PROTOCOL_LEP
//#define FEATURE_ENCLEP_PROTOCOL_SIGNING
//#define FEATURE_ENCLEP_SIGNATURE_VERIFICATION

#define OVERRIDE_STRING_ENRPC_LEP_DOMAIN "CLEP Test Domain"

#include "northbridge-sys/en-framework/lsl/libraries.lsl"

list ENRPC_KEYS = [
    "sample-rpc", "foobar"
];

string TESTER_KEY_NAME = "sample-rpc";

en_state_entry()
{
    #if !defined FEATURE_ENCLEP_PROTOCOL_SIGNING && !defined FEATURE_ENCLEP_SIGNATURE_VERIFICATION
        TESTER_KEY_NAME = ""; // use a blank TESTER_KEY_NAME if signing is disabled, otherwise the messages will be dropped
    #endif
    
    enCLEP_Listen(OVERRIDE_STRING_ENRPC_LEP_DOMAIN, FLAG_ENRPC_LISTEN_OWNERONLY);
}

enrpc_message(
    integer flags,
    string key_name,
    integer source_link,
    list data
)
{
    if (~flags & FLAG_ENRPC_TYPE_REQUEST) return;

    if (key_name != TESTER_KEY_NAME) return; // reject unsigned/missigned messages

    string method = llList2String(data, CONST_ENRPC_DATA_METHOD);
    if (llList2String(data, CONST_ENRPC_DATA_METHOD) != "ping") return; // only respond if method is "ping"

    string domain = llList2String(data, CONST_ENRPC_DATA_DOMAIN);
    string source_region = llList2String(data, CONST_ENRPC_DATA_SOURCE_REGION);
    string source_prim = llList2String(data, CONST_ENRPC_DATA_SOURCE_PRIM);
    string source_script = llList2String(data, CONST_ENRPC_DATA_SOURCE_SCRIPT);
    string id = llList2String(data, CONST_ENRPC_DATA_ID);
    string params = llList2String(data, CONST_ENRPC_DATA_PARAMS);

    enLog_Info("Got " + llList2String(["LEP", "CLEP", "SNEP"], llListFindList([FLAG_ENRPC_PROTOCOL_LEP, FLAG_ENRPC_PROTOCOL_CLEP, FLAG_ENRPC_PROTOCOL_SNEP], [flags & (FLAG_ENRPC_PROTOCOL_LEP | FLAG_ENRPC_PROTOCOL_CLEP | FLAG_ENRPC_PROTOCOL_SNEP)])) + " ping on domain \"" + domain + "\" using key \"" + key_name + "\" with ID \"" + id + "\" and params: " + params);

    // respond to request
    if (flags & FLAG_ENRPC_PROTOCOL_LEP)
    {
        enCLEP_LEPResultSigned(
            TESTER_KEY_NAME, // this must match key_name above (not necessarily in the source)
            source_link, // you may send messages to any link or script, not just the source link
            source_script, // however, typically you'd only respond to the source_link and source_script that sent the request
            domain, // return domain
            method, // return method
            params, // return params
            id, // return id
            "{\"mid\":\"" + llGetTimestamp() + "\"}" // respond with result as timestamp
        );
    }
    if (flags & FLAG_ENRPC_PROTOCOL_CLEP)
    {
        enCLEP_CLEPResultSigned(
            TESTER_KEY_NAME, // this must match key_name above (not necessarily in the source)
            source_region, // source region
            source_prim, // source prim
            source_script, // however, typically you'd only respond to the source_link and source_script that sent the request
            domain, // return over same domain
            method, // return method
            params, // return params
            id, // return id
            "{\"mid\":\"" + llGetTimestamp() + "\"}" // respond with result as timestamp
        );
    }
}

default
{
    #include "northbridge-sys/en-framework/lsl/event-handlers.lsl"
}
