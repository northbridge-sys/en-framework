/*
enKVS.lsl
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

// DO NOT EDIT THIS LINE - LIBRARY CROSS-LOADER
#include "northbridge-sys/en-framework/lsl/libraries.lsl"

// these are done as separate lists for speed, the memory difference is negligible
list _ENKVS_NAMES;
list _ENKVS_DATA;

//  checks if a KVS pair exists by name
integer enKVS_Exists(list name)
{
    #if defined TRACE_ENKVS
        enLog_TraceParams("enKVS_Exists", ["name"], [
            enList_Elem(name)
            ]);
    #endif
	return ~llListFindList(_ENKVS_NAMES, [llDumpList2String(name, "\n")]); // != -1
}

//  writes a KVS pair value
integer enKVS_Write(list name, string data)
{
    #if defined TRACE_ENKVS
        enLog_TraceParams("enKVS_Write", ["name", "data"], [
            enList_Elem(name),
            enString_Elem(data)
            ]);
    #endif
	integer i = llListFindList(_ENKVS_NAMES, [llDumpList2String(name, "\n")]);
	if (~i) enKVS_Delete(name);  // != -1; delete value, then reappend
	_ENKVS_NAMES += [llDumpList2String(name, "\n")];
	_ENKVS_DATA += [data];
	return 1;
}

//  reads a KVS pair value
string enKVS_Read(list name)
{
    #if defined TRACE_ENKVS
        enLog_TraceParams("enKVS_Read", ["name"], [
            enList_Elem(name)
            ]);
    #endif
	integer i = llListFindList(_ENKVS_NAMES, [llDumpList2String(name, "\n")]);
	if (i == -1) return ""; // doesn't exist
	return llList2String(_ENKVS_DATA, i);
}

//  deletes a KVS pair
enKVS_Delete(list name)
{
    #if defined TRACE_ENKVS
        enLog_TraceParams("enKVS_Delete", ["name"], [
            enList_Elem(name)
            ]);
    #endif
	integer i = llListFindList(_ENKVS_NAMES, [llDumpList2String(name, "\n")]);
	if (i == -1) return; // doesn't exist
	_ENKVS_NAMES = llDeleteSubList(_ENKVS_NAMES, i, i);
	_ENKVS_DATA = llDeleteSubList(_ENKVS_DATA, i, i);
}

enKVS_Reset()
{
    #if defined TRACE_ENKVS
        enLog_TraceParams("enKVS_Reset", [], []);
    #endif
    _ENKVS_NAMES = [];
    _ENKVS_DATA = [];
}
