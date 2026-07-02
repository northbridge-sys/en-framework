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

╒══════════════════════════════════════════════════════════════════════════════╕
│ INSTRUCTIONS                                                                 │
└──────────────────────────────────────────────────────────────────────────────┘

This is a full script that reports all LEP messages sent via link_message to
this prim.
*/

#define FEATURE_ENCLEP_ALLOW_ALL_LEP_DOMAINS
#define FEATURE_ENCLEP_ALLOW_ALL_TARGET_SCRIPTS
#define OVERRIDE_ENLOG_DEFAULT_LOGLEVEL 6

#define TRACE_EVENT_ENCLEP_MESSAGE

#include "northbridge-sys/en-framework/lsl/libraries.lsl"

default
{
    #include "northbridge-sys/en-framework/lsl/event-handlers.lsl"
}
