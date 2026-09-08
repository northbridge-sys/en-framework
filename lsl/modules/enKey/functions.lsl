/*
enKey.lsl
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


//  returns 1 if is a valid key (INCLUDING NULL_KEY, unlike the regular if (key) conditional check)
integer enKey_Is(
    string k
    )
{
    if ( (key)k ) return 1;
    return k == NULL_KEY;
}

//  returns 1 if is a valid key, but NOT NULL_KEY
integer enKey_IsNotNull(
    string k
    )
{
    if ( (key)k ) return 1;
    return 0;
}

//  returns 1 if is a key of something that exists IN THIS REGION
integer enKey_IsInRegion(
    string k
    )
{
    if ( enKey_IsAvatarInRegion( k ) ) return 1;
    return enKey_IsPrimInRegion( k );
}

//  returns 1 if a valid avatar key IN THIS REGION
integer enKey_IsAvatarInRegion(
    string k
)
{
    return llGetAgentSize((key)k) != ZERO_VECTOR;
}

//  returns 1 if a valid prim key IN THIS REGION
integer enKey_IsPrimInRegion(
    string k
    )
{
    list d = llGetObjectDetails( (key)k, [ OBJECT_OWNER ] );
    if ( d == [] ) return 0; // not in region
    if ( llList2String( d, 0 ) == llToLower( k ) ) return 0; // is an avatar
    return 1; // must be a prim
}

//  strips dashes out of a key
string enKey_Strip(
    string k
    )
{
    if ( !enKey_Is( k ) ) return k; // not a valid key
    return llReplaceSubString( k, "-", "", 0 ); // valid key, so strip dashes
}

//  adds dashes into a 32-character hex string to turn it into a key
string enKey_Unstrip(
    string k
    )
{
    // TODO: make a hex validator
    if ( llStringLength(k) != 32 ) return k; // not a valid 32-character hex string
    return // inject dashes and return
        llGetSubString(k, 0, 7) + "-" +
        llGetSubString(k, 8, 11) + "-" +
        llGetSubString(k, 12, 15) + "-" +
        llGetSubString(k, 16, 19) + "-" +
        llGetSubString(k, 20, 31);
}

//  strips dashes out of a key and encodes it in Base64 for memory efficiency (36 characters down to 32 in hex, or 24 in Base64)
// WARNING: this is NOT compatible with llbase64 in SLua!
string enKey_Compress(
    string k
    )
{
    if ( !enKey_Is( k ) ) return k; // not a valid key
    k = enKey_Strip( k );
    return llGetSubString(llIntegerToBase64((integer)("0x" + llGetSubString(k, 0, 7))), 0, 5) // concatenate the first 6 characters of Base64 encoding of each 8 nybbles (the remaining is always padding)
        + llGetSubString(llIntegerToBase64((integer)("0x" + llGetSubString(k, 8, 15))), 0, 5)
        + llGetSubString(llIntegerToBase64((integer)("0x" + llGetSubString(k, 16, 23))), 0, 5)
        + llGetSubString(llIntegerToBase64((integer)("0x" + llGetSubString(k, 24, 31))), 0, 5);
}

//  adds dashes back into a key that was sent through enKey_Compress(...)
// WARNING: this is NOT compatible with llbase64 in SLua!
string enKey_Decompress(
    string k
    )
{
    if (llStringLength(k) != 24) return k; // not a compressed key
    // presumptively valid key at this point (no point k checking any further)
    // convert from Base64 to a 32-nybble hex string
    k = enInteger_ToHex(llBase64ToInteger(llGetSubString(k, 0, 5)), 8)
        + enInteger_ToHex(llBase64ToInteger(llGetSubString(k, 6, 11)), 8)
        + enInteger_ToHex(llBase64ToInteger(llGetSubString(k, 12, 17)), 8)
        + enInteger_ToHex(llBase64ToInteger(llGetSubString(k, 18, 23)), 8);
    // inject dashes and return
    return enKey_Unstrip( k );
}

string _enKey_i8ToHex(integer i)
{
    i = (i | 0x3030) + 0x27 * ((i = (i & 0xF0) << 4 | i & 0xF) + 0x0606 >> 4 & 0x0101);
    return llChar(i >> 8 & 0xFF) + llChar(i & 0xFF);
}

string _enKey_i16ToHex(integer i)
{
    i = (i | 0x30303030) + 0x27 * ((i = ((i & 0xF000F0) << 4) | (i = (i & 0xFF00) << 8 | i & 0xFF) & 0x0F000F) + 0x06060606 >> 4 & 0x01010101);
    return llChar(i >> 24 & 0xFF) + llChar(i >> 16 & 0xFF) + llChar(i >> 8 & 0xFF) + llChar(i & 0xFF);
}

string _enKey_i24ToHex(integer i)
{
    return _enKey_i16ToHex(i >> 8 & 0xFFFF) + _enKey_i8ToHex(i & 0xFF);
}

/*
Similar to enKey_Compress, but compresses to 22 characters instead of 24.
This takes considerably more memory so is only recommended if you need to support lljson.slencode/sldecode tight UUIDs.
Authored by Félix (Coyote.Enthusiast) on 2024-03-17. Released CC-0 2025-08-30. Modified for use in En.
*/
string enKey_Compress22(
    string k
)
{
    if (!enKey_Is(k)) return k; // not a valid key
    k = enKey_Strip(k);

    integer i;
    string out;
    for (; i < 32; i += 6)
    {
        integer v = (integer)("0x" + llGetSubString(k, i, i + 5)) << 8;
        if (i == 30)
            v = v << 16;
        out += llGetSubString(llIntegerToBase64(v), 0, 3);
    }
    return llGetSubString(out, i, 21);
}

/*
Similar to enKey_Decompress, but for enKey_Compress22 or lljson.slencode tight UUIDs.
Authored by Félix (Coyote.Enthusiast) on 2024-03-17. Released CC-0 2025-08-30. Modified for use in En.
*/
string enKey_Decompress22(
    string b
)
{
    string out;
    integer i;
    for (; i < 24; i += 4)
    {
        integer x = llBase64ToInteger(llGetSubString(b, i, i+3)) >> 8;
        out += _enKey_i24ToHex(x);
    }
    for (i = 8; i < 24; i += 5)
        out = llInsertString(out, i, "-");
    return llGetSubString(out, 0, 35);
}
