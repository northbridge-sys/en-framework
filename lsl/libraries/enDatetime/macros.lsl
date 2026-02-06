/*
enDatetime
Copyright (C) 2025  Northbridge Business Systems
https://docs.northbridgesys.com/en-framework
*/

#define FLAG_ENDATETIME_12_HOUR 0x1
#define FLAG_ENDATETIME_12_HOUR_M 0x2
#define FLAG_ENDATETIME_12_HOUR_SPACE 0x4
#define FLAG_ENDATETIME_PAD_ZEROES 0x8
#define FLAG_ENDATETIME_DMY 0x10
#define FLAG_ENDATETIME_MDY 0x20
#define FLAG_ENDATETIME_TEXT 0x40
#define FLAG_ENDATETIME_TEXT_DMY 0x80
#define FLAG_ENDATETIME_TEXT_MDY 0x100
#define FLAG_ENDATETIME_TEXT_MONTH_SHORT 0x200
#define FLAG_ENDATETIME_TEXT_MONTH_SHORT_DOT 0x400
#define FLAG_ENDATETIME_TEXT_DAY_ORDINAL 0x800
#define FLAG_ENDATETIME_TEXT_DAY_OF 0x1000
#define FLAG_ENDATETIME_PAD_ZEROES_HOURS 0x2000
#define FLAG_ENDATETIME_PAD_ZEROES_MINUTES 0x4000
#define FLAG_ENDATETIME_PAD_ZEROES_SECONDS 0x8000

#if defined TRACE_EN
    #define TRACE_ENDATETIME
#endif

/*!
Converts current environment time (sun position) at script's location to a percentage of day starting at midnight.
NOTE: this shouldn't be used in attachments maybe because of llGetPos?
@return float Daypart of 24 hours starting at midnight (0.0-1.0).
*/
#define enDatetime_EnvironmentToDaypart_Here() \
    enDatetime_EnvironmentToDaypart(llGetPos())

/*!
Converts current environment time (sun position) at specified location to an HMS list.
Environment sun positions are typically fast enough that subsecond precision is not accurate.
@param vector p Region-scope position.
@return list [h, m, s].
*/
#define enDatetime_EnvironmentToHMS(p) \
    enDatetime_DaypartToHMS(enDatetime_EnvironmentToDaypart(p))

/*!
Converts current environment time (sun position) at script's location to a percentage of day starting at midnight.
Environment sun positions are typically fast enough that subsecond precision is not accurate.
NOTE: this shouldn't be used in attachments maybe because of llGetPos?
@return list [h, m, s].
*/
#define enDatetime_EnvironmentToHMS_Here() \
    enDatetime_EnvironmentToHMS(llGetPos())

/*!
Gets short textual representation of specified month, limited to 3 characters.
Can be called in multiple places with minimal memory impact.
@param integer month Month of year (1-12).
@return string Month of year as 3-character text.
*/
#define enDatetime_MToPrettyShort(month) \
    llDeleteSubString(enDatetime_MToPretty(month), 3, -1)

/*!
Gets the current datetime in enDatetime's millisec format.
@return integer Millisecs.
*/
#define enDatetime_NowToMillisec() \
    enDatetime_TimestampToMillisec(llGetTimestamp())

/*!
Gets current time as ISO 8601 timestamp.
Alias of llGetTimestamp().
@return string ISO 8601 timestamp.
*/
#define enDatetime_NowToTimestamp() \
    llGetTimestamp()

/*!
Gets current time as Unix timestamp.
Alias of llGetUnixTime().
@return integer Unix time.
*/
#define enDatetime_NowToUnix() \
    llGetUnixTime()

/*!
Gets current time as enDatetime list.
For subsecond precision, use enDatetime_NowToYMDHMSU().
@return list [Y, M, D, h, m, s].
*/
#define enDatetime_NowToYMDHMS() \
    enDatetime_UnixToYMDHMS(llGetUnixTime())

/*!
Gets current time as enDatetime list, with subsecond precision.
For integer precision, use enDatetime_NowToYMDHMS().
@return list [Y, M, D, h, m, s, u].
*/
#define enDatetime_NowToYMDHMSU() \
    enDatetime_TimestampToYMDHMSU(llGetTimestamp())

/*!
Get difference between two timestamps in integer seconds, discarding microseconds.
This is imprecise because second 0.999999 is considered 1 second away from 1.000000, but 1.000000 is considered 0 seconds away from 1.999999.
Probably faster and more efficient than enDatetime_TimestampDiffToSecondsPrecise(). TODO: test this
@param string ts_a First timestamp.
@param string ts_b Second timestamp.
@return integer Difference in seconds.
*/
#define enDatetime_TimestampDiffToSeconds(ts_a, ts_b) \
    (enDatetime_TimestampToUnix(ts_b) - enDatetime_TimestampToUnix(ts_a))

/*!
Get difference between two timestamps in float seconds.
@param string ts_a First timestamp.
@param string ts_b Second timestamp.
@return float Difference in seconds, with subseconds.
*/
#define enDatetime_TimestampDiffToSecondsPrecise(ts_a, ts_b) \
    (enDatetime_TimestampDiffToSeconds(ts_a, ts_b) + (llList2Integer(enDatetime_TimestampToYMDHMSU(ts_b), 6) - llList2Integer(enDatetime_TimestampToYMDHMSU(ts_a), 6)) * 0.000001)

/*!
Converts ISO 8601 timestamp to pretty datetime.
@param string t ISO 8601 timestamp. See llGetTimestamp().
@param integer flags FLAG_ENDATETIME_* flags.
@return string Pretty datetime.
*/
#define enDatetime_TimestampToPretty(t, flags) \
    enDatetime_YMDHMSUToPretty(enDatetime_TimestampToYMDHMSU(t), flags)

/*!
Converts ISO 8601 timestamp from llGetTimestamp to Unix timestamp from llGetUnixTime.
No validation is performed. NO subsecond precision.
@param string t ISO 8601 timestamp. See llGetTimestamp().
@return integer Unix time.
*/
#define enDatetime_TimestampToUnix(t) \
    enDatetime_YMDHMSToUnix(enDatetime_TimestampToYMDHMSU(t))

/*!
Converts Unix time to pretty datetime.
@param string Unix time. See llGetUnixTime().
@param integer flags FLAG_ENDATETIME_* flags.
@return string Pretty datetime.
*/
#define enDatetime_UnixToPretty(u, flags) \
    enDatetime_YMDHMSToPretty(enDatetime_UnixToYMDHMS(u), flags)

/*!
Converts Unix time to ISO 8601 timestamp.
@param string Unix time. See llGetUnixTime().
@return string ISO 8601 timestamp.
*/
#define enDatetime_UnixToTimestamp(u) \
    enDatetime_YMDHMSUToTimestamp(enDatetime_UnixToYMDHMS(u))

/*!
Gets full textual representation of specified month.
Avoid calling this in multiple places in the same script, because the entire month list will be stored multiple times in the bytecode! Use enDatetime_MToPretty() instead.
@param integer month Month of year (1-12).
@return string Month of year as full text.
*/
#define _enDatetime_MToPretty(month) \
    llList2String(["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"], month - 1)

/*!
Gets short textual representation of specified month, limited to 3 characters.
Avoid calling this in multiple places in the same script, because the entire month list will be stored multiple times in the bytecode! Use enDatetime_MToPrettyShort() instead.
@param integer month Month of year (1-12).
@return string Month of year as 3-character text.
*/
#define _enDatetime_MToPrettyShort(month) \
    llDeleteSubString(_enDatetime_MToPretty(month), 3, -1)
