/*
enPrim.lsl
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

#define FLAG_ENPRIM_PROFILE_EXISTS 0x80000000
#define FLAG_ENPRIM_PROFILE_PHYSICS 0x1
#define FLAG_ENPRIM_PROFILE_PHANTOM 0x2
#define FLAG_ENPRIM_PROFILE_TEMP_ON_REZ 0x4
#define FLAG_ENPRIM_PROFILE_TEMP_ATTACHED 0x8

#define FLAG_ENPRIM_TEXT_SUCCESS 0x10
#define FLAG_ENPRIM_TEXT_BUSY 0x20
#define FLAG_ENPRIM_TEXT_PROMPT 0x40
#define FLAG_ENPRIM_TEXT_ERROR 0x80
#define FLAG_ENPRIM_TEXT_TEMP 0x100
#define FLAG_ENPRIM_TEXT_PROGRESS_NC 0x200
#define FLAG_ENPRIM_TEXT_PROGRESS_THROB 0x400

#define FLAG_ENPRIM_VM_LSO -1
#define FLAG_ENPRIM_VM_MONO 1

/*
Number of PREVIOUS prim UUIDs to store. By default, this is 2 (_ENPRIM_UUIDS_SELF contains current and previous 2 prim UUIDs).
To disable enPrim_GetMyLast() entirely, set this to 0. Do not do this if you use self-domain relistening, enLNX scopes, or anything else that requires UUID monitoring
*/
#if !defined OVERRIDE_ENPRIM_LIMIT_GETMYLAST
    #define OVERRIDE_ENPRIM_LIMIT_GETMYLAST 2
#endif

list _ENPRIM_UUIDS_SELF;

#if defined FEATURE_ENPRIM_ENABLE_LINK_CACHE
    list _ENPRIM_LINK_CACHE; // prim name, current linknum, max distance
    #define _ENPRIM_LINK_CACHE_STRIDE 3
#endif

#define enPrim_GetLastOwner(prim) \
    llList2String(llGetObjectDetails(prim, [OBJECT_LAST_OWNER_ID]), 0)

#define enPrim_GetLinkColor(link,face) \
    (vector)llList2String(llGetLinkPrimitiveParams(link, [PRIM_COLOR, face]), 0)

#define enPrim_GetLinkAlpha(link,face) \
    (float)llList2String(llGetLinkPrimitiveParams(link, [PRIM_COLOR, face]), 1)

#define enPrim_GetMyLastOwner() \
    enPrim_GetLastOwner(llGetKey())

//  gets UUID of entity that rezzed THIS object
#define enPrim_GetMyParent() \
    enPrim_GetParent(llGetKey())

// gets UUID of root prim in linkset
// if llGetNumberOfPrims() is...
//  1 (unlinked object): index is !(1-1)=!!(0)=0, return llGetLinkKey(0)
//  2+ (linked object): index is !(2-1)=!!(1)=1, reutrn llGetLinkKey(1)
// this is required because llGetLinkKey requires 0 for root in unlinked objects and 1 in linked objects
#define enPrim_GetMyRoot() \
    llGetLinkKey(!!(llGetNumberOfPrims() - 1))

// gets the current object's world position
#define enPrim_GetMyWorldPos() \
    enVector_RegionToWorld(llGetPos())

//  gets UUID of entity that rezzed the specified object
#define enPrim_GetParent(prim) \
    llList2String(llGetObjectDetails(prim, [OBJECT_REZZER_KEY]), 0)

/*!
Gets root of specified prim UUID's linkset. See llGetObjectDetails(), OBJECT_ROOT.
@param string prim Prim UUID.
@return string UUID of root prim.
*/
#define enPrim_GetRoot(prim) \
    llList2String(llGetObjectDetails(llGetKey(), [OBJECT_ROOT]), 0)

// gets the root prim's world position
#define enPrim_GetRootWorldPos() \
    enVector_RegionToWorld(llGetRootPosition())

//  returns either own object's current UUID or one of its previous UUIDs
/*
Returns the last nth UUID of this prim, e.g. the last UUID would be n=1, the one before that n=2, etc.
Limited by OVERRIDE_ENPRIM_LIMIT_GETMYLAST to a maximum of 
*/
#define enPrim_GetMyLast(n) \
    llList2String(_ENPRIM_UUIDS_SELF, n)

/*!
Gets link number of specified prim in its linkset.
Note that there doesn't appear to be a way to confirm that a 0 value here is a missing key and not a single-prim linkset's root. Use some other method to check if the prim exists.
@param string prim Prim UUID.
@return integer Link number.
*/
#define enPrim_GetLinkNumber(prim) \
    (integer)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_LINK_NUMBER]), 0)

// gets another object's world position (same region only), or avatar within the avatar detection range of llGetObjectDetails
// for objects outside that range with known positions, you'll have to do this yourself using enVector_RegionCornerToWorld
// you'll want to first add some sort of validation that the key is in the region, otherwise this just returns the region corner (maybe check for that and hope for the best?)
#define enPrim_GetWorldPos(object_or_avatar_uuid) \
    enVector_RegionToWorld(llList2Vector(llGetObjectDetails(object_or_avatar_uuid, [OBJECT_POS]), 0))

/*!
Returns TRUE if specified prim has the same root as the script's, or FALSE otherwise.
@param string prim Prim UUID to compare to.
@return integer Boolean.
*/
#define enPrim_SameRoot(prim) \
    (enPrim_GetRoot(prim) == enPrim_GetMyRoot())

#define enPrim_StopIfOwnerRezzed() \
    if (enPrim_GetMyParent() == (string)llGetKey()) enLog_FatalStop("enPrim_StopIfOwnerRezzed() triggered")

#define enPrim_StopIfFlagged() \
    if ((integer)llLinksetDataRead("stop")) enLog_FatalStop("enPrim_StopIfFlagged() triggered")
