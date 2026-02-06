/*
enLNX.lsl
Library
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

// uses prim-scope datastore
#define FLAG_ENLNX_PRIM_SCOPE 0x1
// uses script-scope datastore
#define FLAG_ENLNX_SCRIPT_SCOPE 0x2
// typically used with FLAG_ENLNX_PRIM_SCOPE - uses the root prim's prim-scope datastore
#define FLAG_ENLNX_ROOT 0x4

#define FLAG_ENLNX_DELETE_CHILDREN 0x80000000

#define enLNX_Head(flags) \
    _enLNX_BuildHead(flags, llGetScriptName(), llGetKey())

#define enLNX_WriteRaw(flags, name, data) \
    llLinksetDataWrite(enLNX_Head(flags) + name, data, "")

#define enLNX_ReadRaw(flags, name, data) \
    llLinksetDataRead(enLNX_Head(flags) + name, "")
