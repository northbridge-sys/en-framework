/*
enInteger.lsl
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

#define CONST_INTEGER_MAX 0x7FFFFFFF
#define CONST_INTEGER_MIN 0x80000000
#define CONST_INTEGER_NEGATIVE 0x80000000

#ifndef OVERRIDE_ENINTEGER_CHARSET_16
    #define OVERRIDE_ENINTEGER_CHARSET_16 "0123456789abcdef"
#endif
#ifndef OVERRIDE_ENINTEGER_CHARSET_64
    #define OVERRIDE_ENINTEGER_CHARSET_64 "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-="
#endif
#ifndef OVERRIDE_ENINTEGER_CHARSET_256
    #define OVERRIDE_ENINTEGER_CHARSET_256 ""
#endif

#if defined TRACE_EN
    #define TRACE_ENINTEGER
#endif

#define enInteger_Rand() \
    (integer)( "0x" + llGetSubString( llGenerateKey(), 0, 7 ))

// good enough!
#define enInteger_IsPositiveOrZero(i) \
    !(i & CONST_INTEGER_NEGATIVE)
#define enInteger_IsNegative(i) \
    (i & CONST_INTEGER_NEGATIVE)
#define enInteger_GetSignZeroPositive(i) \
    (enInteger_IsPositiveOrZero(i) * 2 - 1)

#define enInteger_InvertNegative(i) \
    (i ^ CONST_INTEGER_NEGATIVE)

// this is not ideal C practice for this implementation due to llAbs
// randomness at ranges larger than CONST_INTEGER_MAX will just have to do it themselves.
// idk what you would even be doing that for tbh
#define enInteger_RandRange(n,x) \
    (n + llAbs(enInteger_Rand()) / (CONST_INTEGER_MAX / (x - n + 1) + 1))

// use enInteger_RandRange unless you absolutely need speed
// this has really bad randomness on low-order bits
#define enInteger_RandRangeFast(n,x) \
    (enInteger_Rand() % (x - n + 1) + n)

// since > and < always return integer 0x1, effectively equivalent to:
//if (i < m || i > x) i = t; // set to target if outside min/max
//return i;
// except at extremely large ranges
#define enInteger_ResetTarget(i,m,x,t) \
    (i + ((t - i) * (i < m || i > x)))

/*
flips bits efficiently
just a reminder that bitwise XOR exists, so you don't try doing any shenanigans with enInteger_SetBit
*/
#define enInteger_FlipBits(bitfield, position) \
    (bitfield ^ position)

/*!
Pushes four bits (one nybble, or one hex) onto the least significant end of an integer, shifting everything else left.
This is mainly used for error code traces (each function appends its error out of 16 options, 0x0 to 0xF), with 0x0 being success.
This allows the resulting caller to quickly check that the procedure was successful by checking (!e).
*/
#define enInteger_PushNybble(nybble, int) \
    (int << 4) | nybble
