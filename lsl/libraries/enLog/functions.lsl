/*
enLog.lsl
Library Functions
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

enLog_To(
    integer level,
    integer line,
    string target, // note - this is NOT related to the "logtarget" check
    string message
)
{
    // can use level 0 to always send, or a level constant for loglevel support
    integer lsd_level = enLog_GetLoglevel();
    string debug_header;
    if (lsd_level >= 5) debug_header = "🔽 [" + llGetSubString(llGetTimestamp(), 11, 21) + "] (" + (string)((integer)((100.0 * llGetUsedMemory()) / llGetMemoryLimit())) + "% " + llGetSubString(llGetKey(), 0, 3) + " @" + (string)line + ") " + llGetScriptName() + "\n";
    if ( lsd_level >= level )
    {
        message = debug_header + llList2String([ // loglevel header, usually an icon but can be anything
            "", // no level
            "🛑 FATAL ERROR: ", // FATAL
            "❌ ERROR: ", // ERROR
            "🚩 WARNING: ", // WARN
            "💬 ", // INFO
            "🪲 ", // DEBUG
            "🚦 " // TRACE
            ], level) + message;
        if ((integer)llLinksetDataRead("logsay")) llSay((integer)llLinksetDataRead("logchannel"), message); // always check logsay for last-resort llSay logging
        if (target == "") llOwnerSay(message); // target to owner
        else llRegionSayTo(target, 0, message); // log to specific user
    }
    #if defined FEATURE_ENLOG_ENABLE_LOGTARGET
        string t = enLog_GetLogtarget();
        string prim = llGetSubString(t, 0, 35); // prim is first 36 chars of logtarget
        if (enKey_IsPrimInRegion(prim))
        { // log via CLEP to logtarget
            string domain = llDeleteSubString(t, 0, 35); // domain is remaining chars of logtarget
            enCLEP_RPCRequest(
                prim, // target_prim
                "", // target_script
                domain, // clep_domain
                level, // int
                "enLog", // method
                "{\"line\":" + (string)line + ",\"ts\":\"" + llGetTimestamp() + "\",\"used\":" + (string)llGetUsedMemory() + ",\"limit\":" + (string)llGetUsedMemory() + "}", // params
                message // id
            );
        }
    #endif
}

// logs a success and stops the script
enLog_SuccessStop(
    string m // message
)
{
    enLog_Success("Script stopped: " + m);
    enLog_Stop();
}

// logs a success and deletes the script (WARNING: SCRIPT IS IRRETRIEVABLE)
enLog_SuccessDelete(
    string m // message
)
{
    enLog_Success("Script deleted: " + m);
    enLog_Delete();
}

// logs a success and deletes the OBJECT (WARNING: OBJECT IS IRRETRIEVABLE IF NOT ATTACHED)
enLog_SuccessDie(
    string m // message
)
{
    enLog_Success("Object " + llList2String(["deleted", "detached from " + enPrim_GetAttachedString(llGetAttached())], !!llGetAttached()) + ": " + m);
    enLog_Die();
}

// logs a fatal error and stops the script
enLog_FatalStop(
    string m // message
    )
{
    enLog_Fatal("Script stopped: " + m);
    enLog_Stop();
}

// logs a fatal error and deletes the script (WARNING: SCRIPT IS IRRETRIEVABLE)
enLog_FatalDelete(
    string m // message
)
{
    enLog_Fatal("Script deleted: " + m);
    enLog_Delete();
}

// logs a fatal error and deletes the OBJECT (WARNING: OBJECT IS IRRETRIEVABLE IF NOT ATTACHED)
enLog_FatalDie(
    string m // message
)
{
    enLog_Fatal("Object " + llList2String(["deleted", "detached from " + enPrim_GetAttachedString(llGetAttached())], !!llGetAttached()) + ": " + m);
    enLog_Die();
}

// stops the script
enLog_Stop()
{
    llSetScriptState(llGetScriptName(), FALSE);
    llSleep(1.0); // give the simulator time to stop the script to be safe
    llResetScript();
}

// deletes the script (WARNING: SCRIPT IS IRRETRIEVABLE)
enLog_Delete()
{
    // remove inventory if FEATURE_ENLOG_ENABLE_DELETE_OWNEDBYCREATOR is defined, OR script is not owned by creator
    #ifndef FEATURE_ENLOG_ENABLE_DELETE_OWNEDBYCREATOR
        if ( enInventory_OwnedByCreator( llGetScriptName() ) ) enLog_Error("Script deletion failed because FEATURE_ENLOG_ENABLE_DELETE_OWNEDBYCREATOR not defined");
        else
    #endif
    // only remove inventory if FEATURE_ENLOG_DISABLE_DELETE is NOT defined
    #if defined FEATURE_ENLOG_DISABLE_DELETE
        enLog_Error("Script deletion failed because FEATURE_ENLOG_DISABLE_DELETE defined");
    #else
        llRemoveInventory(llGetScriptName());
    #endif
    enLog_Stop();
}

// deletes the OBJECT (or, if it is attached, detaches it) (WARNING: OBJECT IS IRRETRIEVABLE IF NOT ATTACHED)
enLog_Die()
{
    // delete object if FEATURE_ENLOG_ENABLE_DIE_OWNEDBYCREATOR is defined, OR script is not owned by creator
    #ifndef FEATURE_ENLOG_ENABLE_DIE_OWNEDBYCREATOR
        if ( enInventory_OwnedByCreator( llGetScriptName() ) ) enLog_Error("Object delete/detach failed because FEATURE_ENLOG_ENABLE_DIE_OWNEDBYCREATOR not defined");
        else
    #endif
    // only delete object if FEATURE_ENLOG_DISABLE_DIE is NOT defined
    #if defined FEATURE_ENLOG_DISABLE_DIE
        enLog_Error("Object delete/detach failed because FEATURE_ENLOG_DISABLE_DIE defined");
    #else
        {
            if (llGetAttached()) llDetachFromAvatar();
            else llDie();
        }
    #endif
    enLog_Stop();
}

// converts integer level number into string representation
string enLog_LevelToString(
    integer l
)
{
    return llList2String(
        [
            "0",
            "Fatal",
            "Error",
            "Warn",
            "Info",
            "Debug",
            "Trace",
            "Unk_" + (string)l
        ],
        l
    );
}

// converts integer level number into string representation
integer enLog_StringToLevel(
    string s
)
{
    return llListFindList(
        [
            "FATAL",
            "ERROR",
            "WARN",
            "INFO",
            "DEBUG",
            "TRACE"
        ],
        [
            llToUpper(llStringTrim(s, STRING_TRIM))
        ]
    ) + 1;
}

// can't do this as a macro because of lists
enLog_Vars(
    integer level,
    list var_names,
    list var_values
    )
{
    enLog_Params(level, "", var_names, var_values);
}

enLog_TraceVars(
    list var_names,
    list var_values
    )
{
    enLog_Vars(TRACE, var_names, var_values);
}

enLog_ParamsResult(
    integer level,
    string function_name,
    list param_names,
    list param_values,
    string result
)
{
    string params;
    if (param_values != []) params = "\n        " + llDumpList2String(enList_Concatenate("", param_names, " = ", param_values, ""), ",\n        ") + "\n    ";
    enLog_To(
        level,
        __LINE__,
        "",
        function_name
            + enString_If(function_name == "", "[", "(")
            + params
            + enString_If(function_name == "", "]", ")")
            + enString_If(result == FLAG_ENLOG_PARAMS_NORESULT, "", " = \"" + result + "\"")
    );
}

enLog_TraceParams(
    string function_name,
    list param_names,
    list param_values
)
{
    enLog_ParamsResult(TRACE, function_name, param_names, param_values, FLAG_ENLOG_PARAMS_NORESULT);
}

enLog_TraceParamsResult(
    string function_name,
    list param_names,
    list param_values,
    string result
)
{
    enLog_ParamsResult(TRACE, function_name, param_names, param_values, result);
}

integer enLog_GetLoglevel()
{
    string lsd = llLinksetDataRead( "loglevel" ); // any valid log level number, 0 (uses default), or negative (suppresses all output)
    if ( (integer)lsd ) return (integer)lsd;
    else return OVERRIDE_ENLOG_DEFAULT_LOGLEVEL;
}

enLog_SetLoglevel(
    integer level
)
{
    if ( level < FATAL || level > TRACE ) return;
    llLinksetDataWrite( "loglevel", (string)level );
}
