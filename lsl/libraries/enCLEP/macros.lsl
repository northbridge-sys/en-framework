/*
enCLEP.lsl
Library Macros
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

// NOTE: do not use FLAG_ENRPC_LISTEN_OWNERONLY across region borders!
#define FLAG_ENRPC_LISTEN_OWNERONLY 0x1
#define FLAG_ENRPC_LISTEN_REMOVE 0x80000000

#ifndef OVERRIDE_INTEGER_ENRPC_RESERVE_LISTENS
    #define OVERRIDE_INTEGER_ENRPC_RESERVE_LISTENS 0
#endif

// used by enRPC_DialogListen()
integer _ENRPC_DIALOG_LSN;

list _ENRPC_CLEP; // domain, flags, handle
#define _ENRPC_CLEP_STRIDE 3

/*
enRPC_Channel is the hashing algorithm that converts a domain into a channel number for CLEP.
This is used to enforce channel separation on different domains. This reduces script time for llRegionSay calls.
CLEP channels are always negative, so we just set the 0x80000000 bit to force a negative integer of some kind.
This also naturally avoids PUBLIC_CHANNEL (0x0 -> 0x80000000) and DEBUG_CHANNEL (0x7FFFFFFF -> 0xFFFFFFFF).
*/
#define enRPC_Channel(domain) \
    (llHash(domain) | CONST_INTEGER_NEGATIVE)

#define enRPC_ReservedListens() \
    (!!_ENRPC_DIALOG_LSN + OVERRIDE_INTEGER_ENRPC_RESERVE_LISTENS)

/*
enRPC_DialogChannel can be used to get the channel we are listing to if enRPC_DialogListen was called.
*/
#define enRPC_DialogChannel() \
    enRPC_Channel((string)llGetInventoryKey(llGetScriptName()))
