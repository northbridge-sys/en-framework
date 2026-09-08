/*
enEnvironment.lsl
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

#if defined TRACE_EN
    #define TRACE_ENENVIRONMENT
#endif

// AmbientLight returns float 0.0 to 1.0 (llVecMag directly returns up to √3)
// by default, AmbientLight > ~0.85 means sun is up
#define enEnvironment_AmbientLight(p) \
    (llVecMag((vector)llList2String(llGetEnvironment(p, [SKY_LIGHT]), 2)) * 0.577334)

// note: this shouldn't be used in attachments maybe because of llGetPos?
#define enEnvironment_AmbientLightHere() \
    (llVecMag((vector)llList2String(llGetEnvironment(llGetPos(), [SKY_LIGHT]), 2)) * 0.577334)

// SunHeight returns float -1.0 to 1.0
// by default, SunHeight > 0.0 means sun is up
#define enEnvironment_SunHeightHere() \
    enEnvironment_SunHeight(llGetPos())
