/*
enInventory.lsl
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


string _ENINVENTORY_NC_N; // notecard name
string _ENINVENTORY_NC_K; // notecard key
integer _ENINVENTORY_NC_L = -1; // notecard line being read
integer _ENINVENTORY_NC_T = -1; // notecard total lines
string _ENINVENTORY_NC_H; // notecard read handle
string _ENINVENTORY_NC_G; // llGetNumberOfNotecardLines handle

list enInventory_List(
    integer t
    )
{
    list x;
    integer i;
    integer l = llGetInventoryNumber(t);
    for (i = 0; i < l; i++)
    {
        x += llGetInventoryName(t, i);
    }
    return x;
}

//  copies an inventory item to another object
integer enInventory_Copy(
    string prim,
    string name,
    integer type,
    integer pin,
    integer run,
    integer param
    )
{
    #if defined TRACE_ENINVENTORY
        enLog_TraceParams("enInventory_Copy", ["prim", "name", "type", "pin", "run", "param"], [
            enPrim_Elem(prim),
            enString_Elem(name),
            type,
            pin,
            run,
            param
            ]);
    #endif
    integer t = llGetInventoryType(name);
    if (type != INVENTORY_ALL && type != t) return 0; // type check failed
    if (t == INVENTORY_NONE) return 0; // can't push anything
    integer p = llGetInventoryPermMask(name, MASK_OWNER);
    if (!(p & PERM_COPY)) return 0; // can't push a no-copy inventory item
    if (t == INVENTORY_SCRIPT && pin) llRemoteLoadScriptPin((key)prim, name, pin, run, param);
    else llGiveInventory((key)prim, name);
    return 1;
}

integer enInventory_OwnedByCreator(
    string name
)
{
    return llGetInventoryCreator( name ) == llGetOwner();
}

//  opens a notecard for enInventory_NC* operations using a partial name
integer enInventory_NCOpenByPartialName(
    string name
)
{
    list ncs = enInventory_List(INVENTORY_NOTECARD);
    integer nc = enList_FindPartial(ncs, name);
    if (nc == -1) return 0;
    else return enInventory_NCOpen(llList2String(ncs, nc));
}

//  opens a notecard for enInventory_NC* operations
integer enInventory_NCOpen(
    string name
    )
{
    #if defined TRACE_ENINVENTORY
        enLog_TraceParams("enInventory_NCOpen", ["name"], [
            enString_Elem(name)
            ]);
    #endif
    #ifndef FEATURE_ENINVENTORY_ENABLE_NC
        enLog_Debug("FEATURE_ENINVENTORY_ENABLE_NC not defined");
        return;
    #endif
    _ENINVENTORY_NC_N = name;
    _ENINVENTORY_NC_L = -1;
    _ENINVENTORY_NC_T = -1;
    _ENINVENTORY_NC_G = llGetNumberOfNotecardLines(_ENINVENTORY_NC_N);
    key new_NC_K = llGetInventoryKey(_ENINVENTORY_NC_N);
    if (new_NC_K == NULL_KEY) return 0; // notecard doesn't exist
    if (new_NC_K == _ENINVENTORY_NC_K) return 0x1; // notecard opened, no changes since last opened
    _ENINVENTORY_NC_K = new_NC_K;
    return 0x3; // notecard opened, changes since last opened
}

//  reads a line from the open notecard
enInventory_NCRead( 
    integer i // line number, starting from 0
    )
{
    #if defined TRACE_ENINVENTORY
        enLog_TraceParams("enInventory_NCRead", ["i"], [
            i
            ]);
    #endif
    #ifndef FEATURE_ENINVENTORY_ENABLE_NC
        enLog_Debug("FEATURE_ENINVENTORY_ENABLE_NC not defined");
        return;
    #else
        if (_ENINVENTORY_NC_N == "")
        {
            enLog_Error("Notecard not opened");
            return;
        }
        _ENINVENTORY_NC_L = i;
        string s = NAK;
        if (llGetFreeMemory() > OVERRIDE_ENINVENTORY_NC_MEMORY_BUFFER && _ENINVENTORY_NC_T > 0) s = llGetNotecardLineSync(_ENINVENTORY_NC_N, i); // attempt sync read if at least 2k of memory free and the llGetNumberOfNotecardLines dataserver event resolved
        if (s == NAK) _ENINVENTORY_NC_H = llGetNotecardLine(_ENINVENTORY_NC_N, i); // sync read failed, do dataserver read
        else eninventory_nc_line(_ENINVENTORY_NC_N, _ENINVENTORY_NC_L, _ENINVENTORY_NC_T, s);
    #endif
}

integer enInventory_NCParse(
    string query,
    string data
    )
{
    if (query == _ENINVENTORY_NC_H)
    {
        #if defined EVENT_ENINVENTORY_NC_LINE
            eninventory_nc_line(_ENINVENTORY_NC_N, _ENINVENTORY_NC_L, _ENINVENTORY_NC_T, data);
        #endif
        return 1;
    }
    if (query == _ENINVENTORY_NC_G)
    {
        _ENINVENTORY_NC_T = (integer)data;
        return 1;
    }
    return 0;
}

//  converts an INVENTORY_* flag into a string (use "INVENTORY_" + llToUpper(enInventory_TypeToString(...)) to get actual flag name)
string enInventory_TypeToString(
    integer f // INVENTORY_* flag
    )
{
    if (f == -1) return ""; // return empty string for INVENTORY_NONE and INVENTORY_ALL
    integer i = llListFindList([
        INVENTORY_TEXTURE,
        INVENTORY_SOUND,
        INVENTORY_LANDMARK,
        INVENTORY_CLOTHING,
        INVENTORY_OBJECT,
        INVENTORY_NOTECARD,
        INVENTORY_SCRIPT,
        INVENTORY_BODYPART,
        INVENTORY_ANIMATION,
        INVENTORY_GESTURE,
        INVENTORY_SETTING,
        INVENTORY_MATERIAL
        ], [f]);
    if (i == -1) return "Unknown"; // return "Unknown" for a flag that is not known by enInventory at compile time
    return llList2String([
        "Texture",
        "Sound",
        "Landmark",
        "Clothing",
        "Object",
        "Notecard",
        "Script",
        "BodyPart",
        "Animation",
        "Gesture",
        "Setting",
        "Material"
        ], i);
}

/*!
Generates a special combined permissions bitfield.
@param string n Name of inventory, or "" for object itself
@return integer Combined permissions bitfield. See CONST_ENINVENTORY_MASK_*_PERM_* for bit indexes.
*/
integer enInventory_GetPerms(
    string n
)
{
    /*
    layout is:
    C = COPY
    M = MODIFY
    T = TRANSFER
    V = MOVE
                    ============ <- ignored (zero)
                                CMTV <- MASK_BASE
                                    CMTV <- MASK_OWNER
                                        CMTV <- MASK_GROUP
                                            CMTV <- MASK_EVERYONE
                                                CMTV <- MASK_NEXT
    32-bit integer: 00000000000000000000000000000000
    */
    integer r;
    integer i;
    for (i = 0; i < 5; i++)
    {
        r = r << 4; // shift existing bits left to make room for these
        integer p;
        if (n == "") p = llGetObjectPermMask(i); // MASK_BASE, MASK_OWNER, MASK_GROUP, MASK_EVERYONE, MASK_NEXT are 0-4
        else p = llGetInventoryPermMask(n, i);
        r += !!(p & PERM_COPY)
            + !!(p & PERM_MODIFY) * 0x2
            + !!(p & PERM_TRANSFER) * 0x4
            + !!(p & PERM_MOVE) * 0x8;
    }
    return r;
}
