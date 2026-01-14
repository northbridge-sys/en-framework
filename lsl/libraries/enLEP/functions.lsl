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
    integer e = _enRPC_Unmarshal(
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
