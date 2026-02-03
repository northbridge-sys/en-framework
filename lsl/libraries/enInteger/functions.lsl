/*
enInteger
Library Functions
En LSL Framework
Copyright (C) 2024  Northbridge Business Systems
https://docs.northbridgesys.com/en-framework
*/

// DO NOT EDIT THIS LINE - LIBRARY CROSS-LOADER
#include "northbridge-sys/en-framework/lsl/libraries.lsl"

/*!
Returns the ordinal text ("st", "nd", "rd", or "th") for a specified number.
@param integer i Number.
@return string Ordinal text. Does not include number.
*/
string enInteger_Ordinal(
    integer i
)
{
    integer t = (i % 100) / 10; // get "ten" place
    if (t == 1) return "th"; // 10-19th
    integer o = i % 10; // get "one" place
    if (o == 1) return "st"; // 1st, 21st, 31st..
    if (o == 2) return "nd"; // 2nd, 22nd, 32nd...
    if (o == 3) return "rd"; // 3rd, 23rd, 33rd...
    return "th"; // 4th, 5th, 6th, 7th, 8th, 9th, etc.
}

string enInteger_ElemBitfield(
    integer var
)
{
    list flags;
    integer bit;
    // TODO: support for non-32-bit bitfields?
    for (bit = 0; bit < 32; bit++)
    {
        integer flag = var & (0x1 << bit);
        if (flag) flags += ["0x" + enInteger_ToHex(flag, 1)];
    }
    return "{" + llList2CSV(flags) + "}";
}

string enInteger_ElemBitfieldLabeled(
    integer var,
    list labels // labels for 0x1, 0x2, 0x4, 0x8, 0x10, 0x20...
)
{
    list flags;
    integer bit;
    // TODO: support for non-32-bit bitfields?

    // start at 0x1, shift left from 0 to 31 times to check each bit through 0x80000000
    for (bit = 0; bit < 32; bit++)
    {
        integer flag = var & (0x1 << bit);
        if (flag) flags += [llList2String(labels, bit) + " (0x" + enInteger_ToHex(flag, 1) + ")"];
    }
    return "{" + llList2CSV(flags) + "}";
}

// converts a 32-bit signed integer in its entirety to hex - for the reverse, use: integer i = (integer)( "0x" + h );
string enInteger_ToHex(
    integer i, // integer
    integer digits // MINIMUM number of hex digits
    )
{
    integer lsn; // least significant nybble
    string hex;
    do
    {
        hex = llGetSubString( OVERRIDE_ENINTEGER_CHARSET_16, lsn = ( i & 0xF ), lsn ) + hex;
        digits--;
    }
    while ( i = ( 0xFFFFFFF & ( i >> 4 ) ) );
    if ( digits > 0 )
    {
        while ( digits-- ) hex = "0" + hex; // pad with leading zeroes until we have reached the minimum digits
    }
    return hex;
}

// grabs the specified nybbles out of an integer
integer enInteger_ToNybbles(
    integer i, // integer
    integer start_index, // start index
    integer digits // number of nybbles to return
    )
{
    while ( --start_index & 0x80000000 ) i = ( 0xFFFFFFF & ( i >> 4 ) ); // drop {start_index} least significant nybbles for
    integer lsn; // least significant nybble
    integer digit; // which digit is being added
    integer nybbles;
    do nybbles = ( ( lsn = ( i & 0xF ) ) << ( 4 * digit++ ) ) | nybbles; // bitwise out the least significant nybble, insert it into nybbles at current digit
    while ( i = ( 0xFFFFFFF & ( i >> 4 ) ) && --digits );
    return nybbles;
}

// converts int to string of length using 64-character charset, ENTYPE_CHARSET_64
string enInteger_ToString64(
    integer int,
    integer length
    )
{
    string o;
    integer x;
    integer y;
    if ( int < 0 )
    { // fix for negative values
        x = ( (0x7FFFFFFF & int) % 64 ) - ( 0x80000000 % 64 );
        y = x % 64;
        int = ( x / 64 ) + ( ( 0x7FFFFFFF & int ) / 64 ) - ( 0x80000000 / 64 );
        o = llGetSubString( OVERRIDE_ENINTEGER_CHARSET_64, y, y );
    }
    do o = llGetSubString( OVERRIDE_ENINTEGER_CHARSET_64, x = int % 64, x ) + o;
    while ( int /= 64 );
    while ( llStringLength(o) < length ) o = "0" + o;
    return o;
}

// inverse of enInteger_ToString64
integer enInteger_FromString64(
    string str
    )
{
    integer i = -llStringLength(str);
    integer x = 0;
    while (i) x = (x * 64) + llSubStringIndex(OVERRIDE_ENINTEGER_CHARSET_64, llGetSubString(str, i, i++));
    return x;
}

integer enInteger_Clamp(
    integer i,
    integer m,
    integer x
    )
{
    if (i < m) i = m; // clamp to minimum
    if (i > x) i = x; // clamp to maximum
    return i;
}

integer enInteger_ResetChunk(
    integer i,
    integer m,
    integer x,
    integer c
)
{
    if (c < 0) c = -c; // make c positive
    if (i < m) i += c * ((m - i) + (c - 1) / c);
    if (i > x) i -= c * ((i - x) + (c - 1) / c);
    return i;
}

/*
sets any number of bitfield positions all to true or false
am i stupid? is there a better way to do this?
*/
integer enInteger_SetBits(
    integer bitfield,
    integer positions,
    integer value
)
{
    if (value) return bitfield | positions;
    return bitfield & ~positions;
}
