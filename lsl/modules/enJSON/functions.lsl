/*
En LSL Framework
Copyright (C) 2026  Northbridge Business Systems
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
SLua's lljson.slencode() implemented in LSL.
Use this to slencode "JSON" for scripts that use lljson.sldecode(), such as CLEP.
Uses tight encoding for vectors and rotations, but not UUIDs.
String values are parsed to see if they are numbers, vectors, rotations (quaternions), uuids, and the words "true" and "false".
String values may be encoded JSON tables or arrays.
@param pairs_strided Must be, e.g., ["utime", 1733341440, "id", "7ef6d0a0-449a-475b-a68e-526fd002e93e", ...]
*/
string enJSON_SLEncodePairs(list pairs_strided)
{
    integer i;
    integer l = llGetListLength(pairs_strided) / 2;
    string output = "{";
    for (i = 0; i < l; i++)
    {
        string value = llList2String(pairs_strided, i * 2 + 1);
        if (enString_IsUUID(value)) value = "\"!u" + value + "\""; // convert to a slencoded uuid
        else if (enString_IsVector(value))
        {
            vector v = enVector_FromString(value);
            value = "\"!v" + enFloat_ToString(v.x, -2) + "," + enFloat_ToString(v.y, -2) + "," + enFloat_ToString(v.z, -2) + "\""; // convert to a slencoded vector
        }
        else if (enString_IsRotation(value))
        {
            rotation r = enRotation_FromString(value, FALSE);
            value = "\"!q" + enFloat_ToString(r.x, -2) + "," + enFloat_ToString(r.y, -2) + "," + enFloat_ToString(r.z, -2) + "," + enFloat_ToString(r.s, -2) + "\""; // convert to a slencoded quaternion
        }
        else if (!enString_IsNumber(value) && value != "true" && value != "false")
        {
            if (llGetSubString(value, 0, 0) == "!") value = "!" + value; // no pistachio disguisey
            value = enString_QuoteJsonString(value); // convert to a json string
        }
        // if it is a number or "true" or "false", we can just drop it right in

        output += enString_QuoteJsonString(llList2String(pairs_strided, i * 2)) + ":" + value + ",";
    }
    if (l) output = llDeleteSubString(output, -1, -1); // we added at least one pair, so delete the final comma
    return output + "}";
}

/*
SLua's lljson.sldecode() implemented in LSL.
Use this to sldecode "JSON" for scripts that use lljson.slencode(), such as CLEP.
Accepts tight encoding for vectors and rotations, but not UUIDs.
All values are encoded to string.
@return [type, name, value, type, name, value, ...] - types are one letter
*/
list enJSON_SLDecodePairs(string json)
{
    list output = llJson2List(json);
    integer i;
    integer l = llGetListLength(output) / 2;
    for (i = 0; i < l; i++)
    {
        string type = "s";
        string name = llList2String(output, i * 3);
        string value = llList2String(output, i * 3 + 1);
        string json_type = llJsonValueType(json, [name]);
        if (json_type == JSON_INVALID) type = "i";
        else if (json_type == JSON_NULL)
        {
            type = "";
            value = "";
        }
        else if (json_type == JSON_NUMBER) type = "n";
        else if (json_type == JSON_ARRAY) type = "a";
        else if (json_type == JSON_OBJECT) type = "o";
        else if (json_type == JSON_TRUE || json_type == JSON_FALSE)
        {
            type = "b";
            if (json_type == JSON_TRUE) value = "true";
            else value = "false";
        }
        if (json_type == JSON_STRING)
        {
            if (llGetSubString(value, 0, 0) == "!")
            {
                type = llGetSubString(value, 1, 1);
                if (type == "u")
                {
                    if (llStringLength(value) == 24)
                        value = enKey_Decompress22(llDeleteSubString(value, 0, 1));
                }
                else if (type == "v")
                    value = (string)enVector_FromString(llDeleteSubString(value, 0, 1));
                else if (type == "r")
                    value = (string)enRotation_FromString(llDeleteSubString(value, 0, 1));
                else
                    value = llDeleteSubString(value, 0, 0);
            }
        }
        output = llListReplaceList(output, [value], i * 3 + 1, i * 3 + 1);
        output = llListInsertList(output, [type], i * 3);
    }
    return output;
}
