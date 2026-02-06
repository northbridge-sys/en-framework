/*
enInventory.lsl
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

// enInventory_GetPerms() return bitfield indexes
#define CONST_ENINVENTORY_MASK_NEXT_PERM_COPY 0x1
#define CONST_ENINVENTORY_MASK_NEXT_PERM_MODIFY 0x2
#define CONST_ENINVENTORY_MASK_NEXT_PERM_TRANSFER 0x4
#define CONST_ENINVENTORY_MASK_NEXT_PERM_MOVE 0x8
#define CONST_ENINVENTORY_MASK_EVERYONE_PERM_COPY 0x10
#define CONST_ENINVENTORY_MASK_EVERYONE_PERM_MODIFY 0x20
#define CONST_ENINVENTORY_MASK_EVERYONE_PERM_TRANSFER 0x40
#define CONST_ENINVENTORY_MASK_EVERYONE_PERM_MOVE 0x80
#define CONST_ENINVENTORY_MASK_GROUP_PERM_COPY 0x100
#define CONST_ENINVENTORY_MASK_GROUP_PERM_MODIFY 0x200
#define CONST_ENINVENTORY_MASK_GROUP_PERM_TRANSFER 0x400
#define CONST_ENINVENTORY_MASK_GROUP_PERM_MOVE 0x800
#define CONST_ENINVENTORY_MASK_OWNER_PERM_COPY 0x1000
#define CONST_ENINVENTORY_MASK_OWNER_PERM_MODIFY 0x2000
#define CONST_ENINVENTORY_MASK_OWNER_PERM_TRANSFER 0x4000
#define CONST_ENINVENTORY_MASK_OWNER_PERM_MOVE 0x8000
#define CONST_ENINVENTORY_MASK_BASE_PERM_COPY 0x10000
#define CONST_ENINVENTORY_MASK_BASE_PERM_MODIFY 0x20000
#define CONST_ENINVENTORY_MASK_BASE_PERM_TRANSFER 0x40000
#define CONST_ENINVENTORY_MASK_BASE_PERM_MOVE 0x80000

#define FLAG_ENINVENTORY_NC_OPENED 0x1
#define FLAG_ENINVENTORY_NC_MODIFIED 0x2

#if defined TRACE_EN
    #define TRACE_ENINVENTORY
#endif

// buffer for free memory available when using llGetNotecardLineSync vs. llGetNotecardLine
// if less than OVERRIDE_ENINVENTORY_NC_MEMORY_BUFFER is available, use llGetNotecardLine
// this allows garbage collection to trigger before the dataserver event is called
#if !defined OVERRIDE_ENINVENTORY_NC_MEMORY_BUFFER
    #define OVERRIDE_ENINVENTORY_NC_MEMORY_BUFFER 8192
#endif

#define enInventory_NCOpenedName() _ENINVENTORY_NC_N
#define enInventory_NCOpenedKey() _ENINVENTORY_NC_K
