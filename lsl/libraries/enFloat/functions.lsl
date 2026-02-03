/*
enFloat.lsl
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

// DO NOT EDIT THIS LINE - LIBRARY CROSS-LOADER
#include "northbridge-sys/en-framework/lsl/libraries.lsl"

//  rounds a float to a specified number of digits after the decimal
string enFloat_ToString(
    float f,
    integer digits
    )
{
    if (!digits) return (string)llRound(f); // no digits after decimal, so just round and return
    // we need to manually return only a certain positive number of digits after the decimal
    string s = (string)f;
    integer i = llSubStringIndex(s, "."); // there are more efficient ways to do this, but whatever
    return llGetSubString(s, 0, i + digits); // return string-cast float, but only up to the number of digits requested
}

//  converts a float to a non-equivalent string, can be converted back with enFloat_Decompress
string enFloat_Compress(
    float f
)
{
    integer i = 0x80000000 & ~llSubStringIndex(llList2CSV([f]), "-");
    if ((f))
    {
        if ((f = llFabs(f)) < 2.3509887016445750159374730744445e-38) i = i | (integer)(f / 1.4012984643248170709237295832899e-45);// denormalized range check & last stride of normalized range
        else if (f > 3.4028234663852885981170418348452e+38) i = i | 0x7F800000;// positive or negative infinity
        else if (f <= 1.4012984643248170709237295832899e-45) i = i | 0x7FC00000; // NaN
        else
        {
            integer temp = ~-llFloor(llLog(f) * 1.4426950408889634073599246810019); // extremes will error towards extremes
            i = i | (0x7FFFFF & (integer)(f * (0x1000000 >> temp))) | ((126 + (temp = ((integer)f - (3 <= (f *= llPow(2, -temp))))) + temp) * 0x800000); // what the fuck?
        }
    }
    return llGetSubString(llIntegerToBase64(i), 0, 5);
}

//  converts the integer result from enFloat_Compress back to a float
float enFloat_Decompress(
    string s
)
{
    integer i = llBase64ToInteger(s);
    if (0x7F800000 & ~i)
        return llPow(2, (i | !i) + 0xffffff6a) * (((!!(i = (0xff & (i >> 23)))) * 0x800000) | (i & 0x7fffff)) * (1 | (i >> 31));
    return (!(i & 0x7FFFFF)) * (float)"inf" * ((i >> 31) | 1);
}

float enFloat_Clamp(
    float i,
    float m,
    float x
    )
{
    if (i < m) i = m; // clamp to minimum
    if (i > x) i = x; // clamp to maximum
    return i;
}

float enFloat_ResetTarget(
    float i,
    float m,
    float x,
    float t
    )
{
    if (i < m || i > x) return t; // return target if outside min/max
    return i;
}

float enFloat_ResetChunk(
    float i,
    float m,
    float x,
    float c
)
{
    if (c < 0) c = -c; // make c positive
    // this is not as efficient as enInteger's version but whatever
    while (i <= m) i += c; // add c until over or equal to min
    while (i > x) i -= c; // subtract c until under max
    return i;
}

integer enFloat_FlipCoin(
    float chance
    )
{
    if ( chance <= 0.0 ) return 0;
    if ( chance >= 1.0 ) return 1;
    if ( llFrand( 1.0 ) < chance ) return 1;
    return 0;
}

float enFloat_RandRange(
    float min,
    float max
    )
{
    return min + llFrand( max - min );
}

/*
attempts to parse out the alpha value from an rgba(0-255, 0-255, 0-255, 0.0-1.0)
if the rgba(R, G, B, A) format is not detected, returns -1.0
see enVector_FromColor to get the RGB values
*/
float enFloat_AlphaFromRGBA(
    string c
)
{
    // strip out all spaces
    c = llReplaceSubString(c, " ", "", 0);
    
    // check for and strip rgba()
    if (llToLower(llGetSubString(c, 0, 4)) != "rgba(" || llGetSubString(c, -1, -1) != ")") return -1.0; // not rgba, return now
    c = llGetSubString(c, 4, -2);

    // parse values
    list v = llParseStringKeepNulls(c, [","], []);
    integer l = llGetListLength(v);
    if (l != 4) return -1.0; // no alpha value

    return (float)llList2String(v, 3);
}
