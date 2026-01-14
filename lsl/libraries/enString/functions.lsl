/*
enString.lsl
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

/*
utility function for safely reading private globals as macro getters
when a getter macro is returned like so:
#define enLibrary_Variable() _ENLIBRARY_VARIABLE
the variable is not actually private, since it can still be modified accidentally like so:
if (enLibrary_Variable() = "foo")
preprocesses into:
if (_ENLIBRARY_VARIABLE = "foo")
whereas if written with enString_Read:
#define enLibrary_Variable() enString_Read(_ENLIBRARY_VARIABLE)
if (enLibrary_Variable() = "foo")
preprocesses into:
if (enString_Read(_ENLIBRARY_VARIABLE) = "foo")
which generates a compile error

NOTE: these should not be left in the code once complete
the memory/performance impact is small but this function is only helpful when compiling, not at runtime
*/
string enString_Read(string s)
{
    return s;
}

//  returns pluralization ("s"/"es"/etc.) for specified integer
//  example:
//      (string)prim_count + " prim" + enString_Plural(prim_count, "s", "") + " counted"
string enString_Plural(
    integer x,
    string s
    )
{
    if (x == 1) return "";
    if (s == "") s = "s"; // default to "s"
    return s;
}

//  returns string a if x is truthy, or b if falsey
//  example:
//      "value is " + enString_If(value, "truthy", "falsey")
string enString_If(
    integer x,
    string a,
    string b
    )
{
    if (x) return a;
    return b;
}

/*
fast, memory-efficient way of left-padding src with leading zeroes up to l_target
use this instead of enString_Pad to save a bunch of memory for numerical uses
note: this does NOT trim src down to l_target!
*/
string enString_PadZeroes(
    string src,
    integer l_target
)
{
    while (llStringLength(src) < l_target) src = "0" + src;
    return src;
}

/*!
Generates sort-of-random hex.
WARNING: This is not safe for cryptography operations, because llGenerateKey's UUID version is subject to change, among other reasons.
@param integer l_target Length of hex string in characters. Each character is 4 bytes.
*/
string enString_GenerateHex(
    integer l_target
)
{
    if (l_target <= 0) return "";
    string r;
    while (llStringLength(r) < l_target) r += enKey_Strip(llGenerateKey());
    return llGetSubString(r, 0, l_target - 1);
}

string enString_Generate(
	string pattern, // pattern to use - typically " "
	integer l_target // number of characters to generate
)
{
    if (pattern == "" || !l_target) return pattern;

    integer i;
    for (i = llStringLength(pattern); i < l_target; i *= 2)
        pattern += pattern;
    return llGetSubString(pattern, 0, l_target - 1);
}

//  pads (or trims) a string to length l_target using specified alignment and padding
//  example:
//      "bank balance: $1" + enString_Pad("5", "0", 5, )
string enString_Pad(
	string src, // string to start with
	string pad, // padding string to use to grow src if necessary
	integer l_target, // number of digits to pad - if POSITIVE, also trims down to this length; if NEGATIVE, only pads to this length, overlength strings will be returned as overlength
	integer flags // either FLAG_ENSTRING_PAD_ALIGN_LEFT, FLAG_ENSTRING_PAD_ALIGN_CENTER, or FLAG_ENSTRING_PAD_ALIGN_RIGHT (note that CENTER uses a left-aligned trim for memory reasons)
)
{
    // len: positive to pad or trim to l_target, negative to only pad (do not trim if already too long)
    // align: 0 = left (pad & trim), 1 = right (pad & trim), 2 = center (pad only, left-aligned trim)
    integer trim;
    if (l_target >= 0) trim = 1; // trim only if len is positive
    else l_target -= 2 * l_target; // too lazy to do some fancy bitwise for this
    integer l_diff = l_target - llStringLength(src);
    if (l_diff < 0 && trim)
    { // overlength
        if (trim)
        { // we're allowed to trim it back down
            if (flags & FLAG_ENSTRING_PAD_ALIGN_LEFT) src = llDeleteSubString(src, 0, -l_diff - 1); // trim from left
            else src = llDeleteSubString(src, l_diff, -1); // trim from right
        }
    }
    if (l_diff > 0)
    { // we need to pad
        if (pad == "") pad = " "; // if pad wasn't specified, we need at least something to pad with
        integer l_pad;
        for (l_pad = llStringLength(pad); l_pad < l_diff; l_pad *= 2) pad += pad; // duplicate pad until it exceeds diff
        if (l_pad > l_diff) pad = llDeleteSubString(pad, -l_pad + l_diff, -1); // trim the pad back down to diff
        if (flags & FLAG_ENSTRING_PAD_ALIGN_CENTER)
        { // center align
            if (l_diff == 1) src += llGetSubString(pad, 0, 0);
            else src = llGetSubString(pad, 0, (l_diff / 2) - 1) + src + llGetSubString(pad, 0, (l_diff - (l_diff / 2)) - 1);
        }
        else if (flags & FLAG_ENSTRING_PAD_ALIGN_RIGHT) src = pad + src; // right align
        else src += pad; // left align
    }
    return src; // return src as-modified
}

//  appends the SI prefix to a specified number of bytes, rounding to the largest possible prefix
//  example:
//      enString_MultiByteUnit(llLinksetDataAvailable()) + "B available in linkset datastore"
string enString_MultiByteUnit(
	integer bytes
	)
{
    integer mult;
    while (bytes >= 1024)
    {
        bytes /= 1024;
        mult++;
    }
    return (string)bytes + llList2String(["", "K", "M", "G"], mult);
}

/*!
Escapes string for use in regex.
Example: llLinksetDataFindKeys("^" + enString_EscapeRegex(needle) + ".*$"")
@param string x Input.
@return string Output.
*/
string enString_EscapeRegex(
    string x
)
{
    list y = ["\\", "^", "$", "*", "+", "?", ".", "(", ")", "|", "{", "}", "[", "]"]; // note that \\ must be the first entry, otherwise previously escaped characters will be double-escaped
    integer i;
    integer l = llGetListLength(y);
    // run llReplaceSubString on each possible character that needs to be escaped
    // this is slow, but takes the least memory compared to llParseStringKeepNulls-based approaches
    for (i = 0; i < l; i++) x = llReplaceSubString(x, llList2String(y, i), "\\" + llList2String(y, i), 0);
    return x;
}

/*!
Escapes " to \", and \ to \\, within the string. Used for JSON escaping.
For some reason, this was causing a compile error as a macro.
@param string s Input.
@return string Output.
*/
string enString_EscapeQuotes(
    string s
)
{
    return llReplaceSubString(llReplaceSubString(s, "\\", "\\\\", 0), "\"", "\\\"", 0);
}

//  finds the first instance of any of the specified characters, used for user input validation
//  example:
//      if (enString_FindChars(input, "|~") != -1) enLog_FatalStop("Pipe (|) or tilde (~) detected in input");
integer enString_FindChars(
    string in,
    string chars
    )
{
    integer i;
    integer l = llStringLength(chars);
    integer x;
    for (i = 0; i < l; i++)
    {
        x = llSubStringIndex(in, llGetSubString(chars, i, i));
        if (~x) return x; // != -1
    }
    return -1;
}

string enString_JsonTryValue(
    string json,
    list specifiers
)
{
    if (llJsonValueType(json, specifiers) != JSON_INVALID) return llJsonGetValue(json, specifiers);
    return "";
}

//  attempts to get a value from a json string, and if fails, returns preset value instead of JSON_INVALID
//  example:
//      color = (vector)enString_JsonTryValueFallback(json, ["set", "color"], (string)color);
//      //  if json contains a "set" object with a "color" value, the function will return it
//      //  otherwise, the function will return the existing value of the color variable
string enString_JsonTryValueFallback(
    string json,
    list specifiers,
    string val
)
{
    string new_val = llJsonGetValue(json, specifiers);
    if (new_val != JSON_INVALID) return new_val;
    return val;
}

/*
parses a string as a command by splitting elements by spaces, except between un-escaped " chars

TODO: this doesn't handle spaces yet! only start/end quotes! don't use this until this message is removed, it doesn't work!
*/
list enString_ParseCommand(
    string line
)
{
    list out;
    string element;
    integer quoted;
    do
    {
        integer quote = llSubStringIndex(line, "\"");
        if (quote == -1)
        { // no quotes remaining in line
            element += line; // append remainder of line to existing element
            return out + [element]; // return out + final element
        }
        if (llGetSubString(line, quote - 1, quote - 1) == "\\" && quote)
        { // this quotation mark is preceded by a backslash, so it's part of the current element
            line = llDeleteSubString(line, quote - 1, quote - 1); // delete escape backslash
            element += llGetSubString(line, 0, quote - 1); // append to element from line from 0 through quote (less backslash)
            line = llDeleteSubString(line, 0, quote - 1); // delete from line from 0 through quote (less backslash)
        }
        else
        { // opening or closing a quoted element
            if (quote > 0) element += llGetSubString(line, 0, quote - 1); // append section of line from start to just before quote to element, if we quoted anything
            out += [element]; // purge element prior to quote (if not already quoted) or quoted element (if already quoted)
            element = "";
            line = llDeleteSubString(line, 0, quote); // delete from line from 0 through quote
            quoted = !quoted;
        }
    } while (TRUE);

    // should not be possible to get here
    return [];
}

/*
returns bytes used by a string in memory
this automatically uses UTF-16 for Mono and UTF-8 for all other scripts
if you know which you're using or need to know the string's size as encoded
in a specific encoding, call enString_UTF*Bytes directly to save memory
*/
integer enString_Bytes(
    string s
)
{
    if (enPrim_VM() == FLAG_ENPRIM_VM_MONO) return enString_UTF16Bytes(); // mono uses UTF-16 strings
    return enString_UTF8Bytes(); // LSO/Lua uses UTF-8 strings (faster to measure)
}

/*
measures bytes used by a string in UTF-8 bytes
WARNING: this is VERY SLOW! consider just doing llStringLength(s) * 2 and assuming no characters are above 0xFFFF
*/
integer enString_UTF16Bytes(
    string s
)
{
    integer b;
    // iterate through each character in the string and figure out how many bytes it would be in UTF-16
    // if any bits above 0xFFFF are true, we are outside the UTF-16 2-byte range, so 4 bytes
    integer l = llStringLength(s);
    for (i = 0; i < l; i++)
        b += 2 + 2 * !!(llOrd(s, i) & 0xFFFF0000);
    return b;
}

/*
sends llOwnerSay, splitting it up into multiple lines for messages over 1024 bytes
WARNING: this is VERY SLOW! it should only be used for reading very large strings while debugging
note that this uses UTF-16 assuming you are using the mono VM!
if you're using LSO/Luau, it should still work, except for code points U+8000 to U+FFFF, which are 3 bytes each in UTF-8
i'll worry about it once Luau actually supports includes
*/
enString_SlownerSay(
    string s
)
{
    integer b; // bytes in "buffer"
    integer x; // buffer start index
    integer i; // current index
    integer l = llStringLength(s);
    for (i = 0; i < l; i++)
    {
        b += 2 + 2 * !!(llOrd(s, i) & 0xFFFF0000);
        if (b > 1020)
        { // flush buffer
            llOwnerSay(llGetSubString(s, x, i));
            x = i + 1;
            b = 0;
        }
    }
    if (x != i) llOwnerSay(llGetSubString(s, x, -1));
}
