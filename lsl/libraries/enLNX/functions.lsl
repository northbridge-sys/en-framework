/*
enLNX.lsl
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


// used to detect script name changes
string _ENLNX_SCRIPT_NAME;

// safely resets LNX namespaces
enLNX_Reset(
    integer flags
)
{
    #if defined TRACE_ENLNX_RESET
        enLog_TraceParams(
            "enLNX_Reset",
            [
                "flags"
            ],
            [
                flags
            ]
        );
    #endif

    // erase all pairs starting with the head defined by flags
    llLinksetDataDeleteFound("^" + enString_EscapeRegex(enLNX_Head(flags)) + ".*$", "");
}

integer enLNX_Write(integer flags, list name, string data)
{
    #if defined TRACE_ENLNX_WRITE
        enLog_TraceParams(
            "enLNX_Write",
            [
                "flags",
                "name",
                "data"
            ],
            [
                flags,
                enList_Elem(name),
                enString_Elem(data)
            ]
        );
    #endif

    integer before = llLinksetDataAvailable();
    integer result = llLinksetDataWrite(enLNX_Head(flags) + llDumpList2String(name, "\n"), data);
    integer after = llLinksetDataAvailable();

    if (FLAG_ENLNX_RETURN_MEMORY_USED) return before - after;
    return result;
}

string enLNX_Read(integer flags, list name)
{
    #if defined TRACE_ENLNX_READ
        enLog_TraceParams(
            "enLNX_Read",
            [
                "flags",
                "name"
            ],
            [
                flags,
                enList_Elem(name)
            ]
        );
    #endif

    return llLinksetDataRead(enLNX_Head(flags) + llDumpList2String(name, "\n"));
}

list enLNX_Delete(integer flags, list name)
{
    #if defined TRACE_ENLNX_WRITE
        enLog_TraceParams(
            "enLNX_Delete",
            [
                "flags",
                "name"
            ],
            [
                flags,
                enList_Elem(name)
            ]
        );
    #endif

    string regex;
    if (flags & FLAG_ENLNX_ALL_CHILDREN) regex = "\n.*";
    if (flags & FLAG_ENLNX_IMMEDIATE_CHILDREN) regex = "\n[^\n]*";
	return llLinksetDataDeleteFound("^" + enString_EscapeRegex(enLNX_Head(flags) + llDumpList2String(name, "\n")) + regex + "$", "");
}

integer enLNX_Exists(integer flags, list name)
{
    return (enLNX_Find(flags, name, 0, 1) != []);
}

list enLNX_Find(integer flags, list name, integer start, integer count)
{
    #if defined TRACE_ENLNX_FIND
        enLog_TraceParams(
            "enLNX_Find",
            [
                "flags",
                "name",
                "start",
                "count"
            ],
            [
                enInteger_ElemBitfield(flags),
                enList_Elem(name),
                start,
                count
            ]
        );
    #endif

    string regex;
    if (flags & FLAG_ENLNX_ALL_CHILDREN) regex = "\n.*";
    if (flags & FLAG_ENLNX_IMMEDIATE_CHILDREN) regex = "\n[^\n]*";
	return llLinksetDataFindKeys("^" + enString_EscapeRegex(enLNX_Head(flags) + llDumpList2String(name, "\n")) + regex + "$", start, count);
}

list enLNX_FindRegex(
    integer flags,
    string regex,
    integer start,
    integer count
)
{ // note: do NOT include ^ and $ anchors in regex string, they will be added automatically
    #if defined TRACE_ENLNX_FINDREGEX
        enLog_TraceParams(
            "enLNX_FindRegex",
            [
                "flags",
                "regex",
                "start",
                "count"
            ],
            [
                enInteger_ElemBitfield(flags),
                enString_Elem(regex),
                start,
                count
            ]
        );
    #endif
	return llLinksetDataFindKeys("^" + enString_EscapeRegex(enLNX_Head(flags)) + regex + "$", start, count);
}

list enLNX_DeleteRegex(
    integer flags,
    string regex
)
{ // note: do NOT include ^ and $ anchors in regex string, they will be added automatically
    #if defined TRACE_ENLNX_DELETEREGEX
        enLog_TraceParams(
            "enLNX_DeleteRegex",
            [
                "flags",
                "regex"
            ],
            [
                enInteger_ElemBitfield(flags),
                enString_Elem(regex)
            ]
        );
    #endif

	return llLinksetDataDeleteFound("^" + enString_EscapeRegex(enLNX_Head(flags)) + regex + "$", "");
}

string _enLNX_BuildHead(
    integer flags,
    string script_name,
    string prim_uuid
)
{
    if (~flags & FLAG_ENLNX_SCRIPT_SCOPE) script_name = ""; // erase script_name if we are not in script-scope namespace
    if (~flags & (FLAG_ENLNX_SCRIPT_SCOPE | FLAG_ENLNX_PRIM_SCOPE)) prim_uuid = ""; // we are not using prim- or script-scope namespace, so erase prim_uuid (linkset-scope)
    else if (flags & FLAG_ENLNX_ROOT) prim_uuid = enPrim_GetMyRoot(); // if we are specifically using the root namespace, replace prim_uuid if we are using prim- or script-scope namespace
    return llReplaceSubString(prim_uuid, "\n", "", 0) + "\n" + llReplaceSubString(script_name, "\n", "", 0) + "\n"; // filter out newlines to enforce LNX spec compliance
}

//  purges all enLNX pairs assigned to UUIDs that are not part of this linkset
enLNX_Purge()
{
    #if defined TRACE_ENLNX_PURGE
        enLog_TraceParams("enLNX_Purge", [], []);
    #endif

    string root = enPrim_GetMyRoot();
    list pair;
    integer i;
    integer start = llLinksetDataCountKeys();
    do
    {
        pair = llLinksetDataFindKeys("^[0-9a-fA-F-]{36}\n.*$", i, 1);
        if (pair != [])
        {
            string prim = llGetSubString(llList2String(pair, 0), 0, 35);
            string prim_root = llList2String(llGetObjectDetails((key)prim, [OBJECT_ROOT]), 0);
            string script = llList2String(pair, 1);
            if (prim != "" && prim_root != root)
            { // this pair is associated with a prim that doesn't share the same root as us
                enLog_Debug("Purging enLNX pairs associated with prim " + enPrim_Elem(prim) + " (root " + enPrim_Elem(prim_root) + ")");
                llLinksetDataDeleteFound("^" + prim + "\n.*$", ""); // delete all pairs scoped to this prim, since it's gone
                i = 0; // start search again
            }
            else if (script != "" && prim == (string)llGetKey() && llGetInventoryType(script) != INVENTORY_SCRIPT)
            { // this pair is associated with a script that is no longer in this prim
                enLog_Debug("Purging enLNX pairs associated with script \"" + script + "\" in prim " + enPrim_Elem(prim) + " (root " + enPrim_Elem(prim_root) + ")");
                llLinksetDataDeleteFound("^" + prim + "\n" + enString_EscapeRegex(script) + "\n.*$", ""); // delete all pairs scoped to this prim & script, since it's gone
                i = 0; // start search again
            }
            else i++; // progress to next index
        }
    }
    while (pair != []);
    enLog_Debug("Purged " + (string)(start - llLinksetDataCountKeys()) + " enLNX pairs");
}

// converts a raw LSD pair name to an enLNX name list
list enLNX_PairToName(
    string pair
)
{
    if (pair == "") return [];
    list elems = llParseStringKeepNulls(pair, ["\n"], []);
    return llDeleteSubList(elems, 0, 1); // trim out scope
}

/*
NOTE: FLAG_ENLNX_PRIM_SCOPE and FLAG_ENLNX_SCRIPT_SCOPE do not limit the scope of migration, but rather the method:
FLAG_ENLNX_PRIM_SCOPE migrates pairs where the old prim_uuid matches the filter, which is replaced by llGetKey()
FLAG_ENLNX_SCRIPT_SCOPE migrates pairs where the old prim_uuid matches llGetKey() and the old script_name matches the filter, which is replaced by llGetScriptName()
*/
enLNX_Migrate(
    integer flags,
    string filter
)
{
    1; // used to fix linter

    #if defined TRACE_ENLNX_MIGRATE
        enLog_TraceParams(
            "enLNX_Migrate",
            [
                "flags",
                "filter"
            ],
            [
                enInteger_ElemBitfield(flags),
                enString_Elem(filter)
            ]
        );
    #endif

    // can't migrate anything if we haven't enabled LNX scopes - this is for memory management
    #if defined FEATURE_ENLNX_ENABLE_SCOPE
        // can't migrate linkset-scope pairs in prim mode, or linkset/prim-scope pairs in script mode
        // can't migrate linkset-scope pairs (neither scope flag set)
        // can't migrate if both flags are set
        if (filter == "" || ~flags & (FLAG_ENLNX_PRIM_SCOPE | FLAG_ENLNX_SCRIPT_SCOPE) || (flags & FLAG_ENLNX_PRIM_SCOPE && flags & FLAG_ENLNX_SCRIPT_SCOPE)) return;
        if (flags & FLAG_ENLNX_PRIM_SCOPE) enLog_Debug("Migrating LNX datastore for prim " + enPrim_Elem(filter));
        else enLog_Debug("Migrating LNX datastore for script " + enString_EscapedQuote(filter));
        list l;
        do
        {
            if (flags & FLAG_ENLNX_PRIM_SCOPE) // find keys where prim_uuid matches filter, any script_name
                l = llLinksetDataFindKeys("^" + enString_EscapeRegex(filter) + "\n.*\n.*$", 0, 1);
            else // find keys where prim_uuid is llGetKey(), and script_name matches filter
                l = llLinksetDataFindKeys("^" + (string)llGetKey() + "\n" + enString_EscapeRegex(filter) + "\n.*$", 0, 1);
            if (l != [])
            {
                list old_pair = llParseStringKeepNulls(llList2String(l, 0), ["\n"], []);
                string old_prim_uuid = llList2String(old_pair, 0);
                string old_script_name = llList2String(old_pair, 1);

                list new_pair;
                if (flags & FLAG_ENLNX_PRIM_SCOPE) // replace prim_uuid
                    new_pair = llListReplaceList(new_pair, [(string)llGetKey()], 0, 0);
                else // replace script_name
                    new_pair = llListReplaceList(new_pair, [llGetScriptName()], 1, 1);

                string type = "prim-scope";
                if (old_script_name != "") type = "script-scope (\"" + enString_EscapeQuotes(old_script_name) + "\")";
                enLog_Trace("LNX " + type + " pair [\"" + llDumpList2String(llList2List(old_pair, 2, -1), "\", \"") + "\"] migrated");
                
                llLinksetDataWrite(llDumpList2String(new_pair, "\n"), llLinksetDataRead(old_pair)); // write with modified pair name
                llLinksetDataDelete(old_pair); // immediately delete old pair
            }
        }
        while (l != []); // repeat until we didn't find any keys left with old header
    #endif
}

// updates LSD entries that use old script name
enLNX_CheckScriptName()
{
    1; // used to fix linter

    #if defined TRACE_ENLNX_CHECKSCRIPTNAME
        enLog_Trace("enLNX_CheckScriptName()");
    #endif

    #if defined FEATURE_ENLNX_ENABLE_SCOPE
        if (llGetScriptName() == _ENLNX_SCRIPT_NAME) return; // no script name change
        if (_ENLNX_SCRIPT_NAME != "")
        {
            enLog_Debug("Migrating LNX namespaces due to script name change");
            enLNX_Migrate(FLAG_ENLNX_SCRIPT_SCOPE, _ENLNX_SCRIPT_NAME);
        }
        _ENLNX_SCRIPT_NAME = llGetScriptName();
    #endif
}

_enLNX_uuid_changed(
    string last_uuid
)
{
    1; // used to fix linter

    #if defined TRACE_ENLNX_UUID_CHANGED
        enLog_TraceParams(
            "_enLNX_uuid_changed",
            [
                "last_uuid"
            ],
            [
                enString_Elem(last_uuid)
            ]
        );
    #endif

    // if FEATURE_ENLNX_PRIM_MONITOR is not defined, we do not need to migrate
    #if defined FEATURE_ENLNX_ENABLE_SCOPE && defined FEATURE_ENLNX_PRIM_MONITOR
        enLog_Debug("Migrating LNX namespaces due to prim UUID change");
        enLNX_Migrate(FLAG_ENLNX_PRIM_SCOPE, last_uuid);
    #endif
}

_enLNX_changed(
    integer change
)
{
    1; // used to fix linter

    #if defined TRACE_ENLNX_CHANGED
        enLog_TraceParams(
            "_enLNX_changed",
            [
                "change"
            ],
            [
                enInteger_ElemBitfield(change)
            ]
        );
    #endif

    #if defined FEATURE_ENLNX_ENABLE_SCOPE
        if (change & CHANGED_INVENTORY) enLNX_CheckScriptName(); // migrate script-scope pairs to new script name
    #endif
}

_enLNX_on_rez(
    integer param
)
{
    1; // used to fix linter

    #if defined TRACE_ENLNX_ON_REZ
        enLog_TraceParams(
            "_enLNX_on_rez",
            [
                "param"
            ],
            [
                param
            ]
        );
    #endif

    // update enLNX names if any use the UUID header
    #if defined FEATURE_ENLNX_ENABLE_SCOPE && defined FEATURE_ENLNX_PRIM_MONITOR
        _enLNX_uuid_changed(enPrim_GetMyLast(1));
    #endif
}
