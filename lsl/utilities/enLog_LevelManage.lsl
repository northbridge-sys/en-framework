/*
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

╒══════════════════════════════════════════════════════════════════════════════╕
│ INSTRUCTIONS                                                                 │
└──────────────────────────────────────────────────────────────────────────────┘

This is a full script that sets the loglevel used by enLog functions. This value
is stored in the "loglevel" linkset data pair. Unlike SetLoglevel, this script
will remain in the object and editing its name will change the loglevel.

This script must be named with the desired loglevel as the last element of the
script's name. For example, "En ManageLoglevel.lsl INFO" causes En scripts in
the same linkset to use the default loglevel (INFO). The text in front of the
desired loglevel can be anything (or nothing).

Loglevel can be FATAL, ERROR, WARN, INFO, DEBUG, or TRACE.
*/

#include "northbridge-sys/en-framework/lsl/libraries.lsl"

setLoglevel()
{
    integer loglevel = enLog_StringToLevel(
        llList2String(
            llParseStringKeepNulls(
                llStringTrim(
                    llGetScriptName(),
                    STRING_TRIM
                    ),
                [ " " ],
                []
                ),
            -1
            )
        );
    if ( !loglevel )
    {
        enLog_Error("Could not read desired loglevel. Rename this script so that the last word is a valid loglevel (FATAL, ERROR, WARN, INFO, DEBUG, or TRACE)." );
        return;
    }
    string lsd = llLinksetDataRead( "loglevel" );
    llLinksetDataWrite( "loglevel", (string)loglevel );
    if ( lsd != "0" && !(integer)lsd ) enLog_Print( "Set loglevel to " + enLog_LevelToString( loglevel ) + "." );
    else if ( lsd != (string)loglevel ) enLog_Print( "Changed loglevel from " + enLog_LevelToString( (integer)lsd ) + " to " + enLog_LevelToString( loglevel ) + "." );
}

default
{
    state_entry()
    {
        setLoglevel();
    }
    changed(integer change)
    {
        if ( change & CHANGED_INVENTORY ) setLoglevel();
    }
}
