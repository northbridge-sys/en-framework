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

// internal flags
#define FLAG_ENCLEP_USE_LINK_MESSAGE 0x1
#define FLAG_ENCLEP_USE_CHAT 0x2
#define FLAG_ENCLEP_RETURN 0x8

#if !defined OVERRIDE_INTEGER_ENCLEP_LINK_MESSAGE_SCOPE
    #define OVERRIDE_INTEGER_ENCLEP_LINK_MESSAGE_SCOPE LINK_THIS
#endif

#if !defined OVERRIDE_STRING_ENCLEP_LINK_MESSAGE_DOMAIN
    #define OVERRIDE_STRING_ENCLEP_LINK_MESSAGE_DOMAIN ""
#endif

#define enCLEP_ResetSourceRegion() \
    enCLEP_StageSourceRegion("")

#define enCLEP_ResetSourcePrim() \
    enCLEP_StageSourcePrim("")

#define enCLEP_ListenRemove(domain) \
    enCLEP_Listen(domain, FLAG_ENCLEP_LISTEN_REMOVE)

// NOTE: do not use FLAG_ENCLEP_LISTEN_OWNERONLY across region borders!
#define FLAG_ENCLEP_LISTEN_OWNERONLY 0x1
#define FLAG_ENCLEP_LISTEN_REMOVE 0x80000000

#ifndef OVERRIDE_INTEGER_ENCLEP_RESERVE_LISTENS
    #define OVERRIDE_INTEGER_ENCLEP_RESERVE_LISTENS 0
#endif

/*
enCLEP_Channel is the hashing algorithm that converts a domain into a channel number for CLEP.
This is used to enforce channel separation on different domains. This reduces script time for llRegionSay calls.
-- ORing with 0x80000000 guarantees the number is negative, which can't be sent via typical viewers
-- ORing with 0x40000000 guarantees the number is lower than -1073741807, which is basically fair game for conflicts
-- the resultant channel space is 30 bits, which is probably more than enough
*/
#define enCLEP_Channel(domain) \
    (llHash(domain) | 0xC0000000)

#define enCLEP_ReservedListens() \
    (!!_ENCLEP_DIALOG_LSN + OVERRIDE_INTEGER_ENCLEP_RESERVE_LISTENS)

/*
enCLEP_DialogChannel can be used to get the channel we are listing to if enCLEP_DialogListen was called.
*/
#define enCLEP_DialogChannel() \
    enCLEP_Channel((string)llGetInventoryKey(llGetScriptName()))
