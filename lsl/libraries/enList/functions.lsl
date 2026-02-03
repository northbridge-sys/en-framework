/*
enList.lsl
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

string enList_Elem(list var)
{
    if (var == []) return "[]";
    return "[\"" + llDumpList2String(var, "\", \"") + "\"]";
}

string enList_ElemNumbers(list var)
{
    return "[" + llDumpList2String(var, ", ") + "]";
}

// if a list only has one element that is a blank string, convert it to an empty list
list enList_Empty(
    list in
    )
{
    if (llGetListLength(in) == 1)
    {
        if (llList2String(in, 0) == "") in = [];
    }
    return in;
}

// returns list element a if x is truthy, or b if falsey
list enList_If(
    integer x,
    list a,
    list b
    )
{
    if (x) return a;
    return b;
}

// returns a string with each second element converted to an escaped JSON string
list enList_ToJsonPairs(
    list in
)
{
    list out;
    integer i;
    integer l = llGetListLength(in);
    for (i = 0; i < l; i++)
    {
        if (i % 2) out += ["\"" + enString_EscapeQuotes(llList2String(in, i)) + "\""]; // value
        else out += [enString_EscapeQuotes(llList2String(in, i))]; // key - must be raw string, otherwise llList2Json breaks
    }
    return out;
}

// fast way to generate a JSON object safely with all string values
// can't be a macro because the preprocessor doesn't like list parameters
string enList_ToJsonObject(
    list in
)
{
    return llList2Json(JSON_OBJECT, enList_ToJsonPairs(in));
}

/*!
Generates a JSON array, converting everything to strings.
llList2Json interprets values as non-strings, causing weird effects (turning "true" to JSON_TRUE, etc.); this converts them all to strings first.
@param list in Input values for array.
@return string JSON array.
*/
string enList_ToJsonArray(
    list in
)
{
    list out;
    integer i;
    integer l = llGetListLength(in);
    for (i = 0; i < l; i++)
        out += ["\"" + enString_EscapeQuotes(llList2String(in, i)) + "\""];
    return "[" + llDumpList2String(out, ",") + "]";
}

list enList_Reverse(
    list l
)
{
    integer n = (l != []);
    while (n)
    {
        l += llList2List(l, (n = ~-n), n);
    }
    return llList2List(l, (l != []) >> 1, -1);
}

// previously enList_Collate
list enList_Interleave(
    list a,
    list b
    )
{
    list out;
    integer i;
    integer l = llGetListLength(a);
    if (llGetListLength(b) > l) l = llGetListLength(b);
    for (i = 0; i < l; i++) out += llList2List(a, i, i) + llList2List(b, i, i);
    return out;
}

// combines list b into a; each element of b is appended to a if it doesn't already exist in a
// note that since type matching is enforced, the types must match
list enList_Combine(
    list a,
    list b
)
{
    integer i;
    integer l = llGetListLength(b);
    for (i = 0; i < l; i++)
    {
        if (llListFindList(a, llList2List(b, i, i)) == -1) a += llList2List(b, i, i);
    }
    return a;
}

list enList_Concatenate(
    string start,
    list a,
    string mid,
    list b,
    string end
    )
{
    list out;
    integer i;
    integer l = llGetListLength(a);
    if (llGetListLength(b) > l) l = llGetListLength(b);
    for (i = 0; i < l; i++) out += [start + llList2String(a, i) + mid + llList2String(b, i) + end];
    return out;
}

/* benchmark results for various ToString implementations:
[22:50] Object: Testing enList_Legacy_ToString
Started with 15264 bytes used
Ended with 15450 bytes used
 Time Running Per Cycle: 0.002113 seconds
 
[22:49] Object: Testing enList_Legacy_FromString
Started with 25490 bytes used
Ended with 26144 bytes used
 Time Running Per Cycle: 0.008785 seconds
 
[22:51] Object: Testing enList_ToEscapedCSV
Started with 15242 bytes used
Ended with 15540 bytes used
 Time Running Per Cycle: 0.002673 seconds
 
[22:52] Object: Testing enList_FromEscapedCSV
Started with 16760 bytes used
Ended with 17000 bytes used
 Time Running Per Cycle: 0.004608 seconds
 
[22:55] Object: Testing enList_FromEscapedCSV llListReplaceList
Started with 16760 bytes used
Ended with 17116 bytes used
 Time Running Per Cycle: 0.005356 seconds
*/

// converts a list into a string without worrying about separators or JSON
// it turns out this is the fastest way to do it safely in all cases, because a CSV of URLs is naturally safe dropped into basically any raw encoding other than CSV itself
// any other solution requiring manual escaping would still require you to iterate through the input anyway
string enList_ToEscapedCSV(
    list in
)
{
    string out;
    integer i;
    integer l = llGetListLength(in);
    for ( i = 0; i < l; i++ )
    {
        out += llEscapeURL(llList2String(in, i)) + ",";
    }
    return out;
}

// converts a list into a string without worrying about separators or JSON
string enList_Legacy_ToString(
    list in
    )
{
    string out;
    integer i;
    integer l = llGetListLength( in );
    string elem;
    for ( i = 0; i < l; i++ )
    {
        elem = llList2String( in, i );
        out += (string)llStringLength( elem ) + " " + elem;
    }
    return "𒂗L" + (string)l + " " + out + " ";
}

// converts a string generated by enList_ToEscapedCSV(...) back into a list
list enList_FromEscapedCSV(
    string in
    )
{
    if (in == "") return []; // empty list
    list out = llCSV2List(in);
    if (llList2String(out, -1) != "") return []; // input string was truncated
    // WARNING: if the string is truncated exactly after a comma, this will not be caught!

    /* tested slower - 0.005356 seconds vs. 0.004608 seconds - also takes more memory somehow
    integer i;
    integer l = llGetListLength(out) - 1; // don't bother with padding element
    for (i = 0; i < l; i++)
    {
        out = llListReplaceList(out, [llUnescapeURL(llList2String(out, i))], i, i);
    }
    */
    list unescaped;
    integer i;
    integer l = llGetListLength(out) - 1; // don't bother with padding element
    for (i = 0; i < l; i++)
    {
        unescaped += [llUnescapeURL(llList2String(out, i))];
    }
    
    return unescaped;
}

// converts a string generated by enList_ToEscapedCSV(...) back into a list
list enList_Legacy_FromString(
    string in
    )
{
    if (llGetSubString(in, 0, 1) != "𒂗L") return []; // not a enList string
    in = llDeleteSubString(in, 0, 1);
    integer length = llStringLength( in ); // count length once for speed
    integer space = llSubStringIndex( in, " " ); // find header delineator - int before this is number of elements
    integer count;
    integer expect = (integer)llGetSubString( in, 0, space - 1 );
    in = llDeleteSubString( in, 0, space ); // trim elem_expect header off
    length -= space + 1; // reduce total length counter
    string elem;
    integer elem_length = 1;
    list out;
    while ( length > 1 && space )
    { // for each element
        space = llSubStringIndex( in, " " ); // find header delineator - int before this is length of element body
        elem_length = (integer)llGetSubString( in, 0, space - 1 );
        if ( !elem_length ) elem = ""; // llGetSubString can't return an empty string
        else elem = llGetSubString( in, space + 1, space + elem_length );
        if (llStringLength(elem) == elem_length) out += [ elem ]; // only add if element has not been truncated
        in = llDeleteSubString( in, 0, space + elem_length ); // trim element off
        length -= space + elem_length + 1; // reduce total length counter
    }
    if ( in != " " )
    {
        enLog_Debug("enList_Legacy_FromString failed due to truncation");
        return []; // all that should be left is the end-of-list space
    }
    return out;
}

// llListFindList but needle can be only part of the element instead of the entire element
integer enList_FindPartial(
    list x,
    string s
    )
{
    integer i;
    integer l = llGetListLength(x);
    for (i = 0; i < l; i++)
    {
        if (~llSubStringIndex(llList2String(x, i), s)) return i; // != -1
    }
    return -1;
}

list enList_DeleteStrideByMatch(
    list haystack,
    integer stride,
    integer index,
    list needle
    )
{
    integer i = llListFindList(llList2ListSlice(haystack, 0, -1, stride, index), needle);
    if (~i) return llDeleteSubList(haystack, i * stride, (i + 1) * stride - 1);  // != -1; delete existing stride because we'll be re-adding it
    return haystack;
}

list enList_ReplaceExact(
    list haystack,
    list needle,
    list new
    )
{
    integer l = llGetListLength(needle);
    integer ind;
    do
    {
        ind = llListFindList(haystack, needle);
        if (~ind) haystack = llListReplaceList(haystack, new, ind, ind + l - 1); // != -1
    }
    while (~ind); // != -1
    return haystack;
}

string enList_RandomElement(
    list l
)
{
    return llList2String(l, (integer)llFrand((float)llGetListLength(l)));
}

/*!
Cast function for all list elements.
Used when you have a mixed or string list that needs to be entirely integers.
@param list l List to convert into integers.
@return list List converted to integers.
*/
list enList_AllToInteger(
    list input
)
{
    integer i;
    integer l = llGetListLength(input);
    list r;
    for (i = 0; i < l; i++)
        r += [(integer)llList2String(input, i)];
    return r;
}
