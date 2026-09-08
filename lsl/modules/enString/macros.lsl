/*
enString.lsl
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

#define FLAG_ENSTRING_PAD_ALIGN_LEFT 0
#define FLAG_ENSTRING_PAD_ALIGN_RIGHT 1
#define FLAG_ENSTRING_PAD_ALIGN_CENTER 2
#define FLAG_ENSTRING_ESCAPE_FILTER_REGEX 0x1
#define FLAG_ENSTRING_ESCAPE_FILTER_JSON 0x2
#define FLAG_ENSTRING_ESCAPE_REVERSE 0x40000000

#define enString_Elem(s) enString_Quote(s)

#define enString_UTF8Bytes(s) ((llStringLength((string)llParseString2List(llStringToBase64(s), ["="], [])) * 3) >> 2)

#define enString_EscapedQuote(s) "\"" + llReplaceSubString(llReplaceSubString(s, "\\", "\\\\", 0), "\"", "\\\"", 0) + "\""

#define enString_Quote(s) "\"" + s + "\""

#define enString_EscapeJsonString(s) enString_EscapeQuotes(s)

#define enString_QuoteJsonString(s) enString_EscapedQuote(s)

#define enString_IsKey(s) enKey_Is(s)

#define enString_IsUUID(s) enKey_Is(s)
