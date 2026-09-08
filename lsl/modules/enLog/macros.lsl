/*
enLog.lsl
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

#define PRINT 0
#define FATAL 1
#define ERROR 2
#define WARN 3
#define INFO 4
#define DEBUG 5
#define TRACE 6

// U+FFFF
#define FLAG_ENLOG_PARAMS_NORESULT "￿"

#ifndef OVERRIDE_ENLOG_DEFAULT_LOGLEVEL
    #define OVERRIDE_ENLOG_DEFAULT_LOGLEVEL INFO
#endif

#if defined TRACE_EN
    #define TRACE_ENLOG
#endif

#define _enLog_Memory() "Memory: " + (string)llGetUsedMemory() + " used, " + (string)llGetSPMaxMemory() + " max, " + (string)llGetMemoryLimit() + " limit, " + (string)llGetFreeMemory() + " free"

#define enLog_PrintMemory() enLog_To(0, __LINE__, "", _enLog_Memory())
#define enLog_FatalMemory() enLog_To(1, __LINE__, "", _enLog_Memory())
#define enLog_ErrorMemory() enLog_To(2, __LINE__, "", _enLog_Memory())
#define enLog_WarnMemory()  enLog_To(3, __LINE__, "", _enLog_Memory())
#define enLog_InfoMemory()  enLog_To(4, __LINE__, "", _enLog_Memory())
#define enLog_DebugMemory() enLog_To(5, __LINE__, "", _enLog_Memory())
#define enLog_TraceMemory() enLog_To(6, __LINE__, "", _enLog_Memory())

#define enLog_Print(message) enLog_To(0, __LINE__, "", message)
#define enLog_Fatal(message) enLog_To(1, __LINE__, "", message)
#define enLog_Error(message) enLog_To(2, __LINE__, "", message)
#define enLog_Warn(message)  enLog_To(3, __LINE__, "", message)
#define enLog_Info(message)  enLog_To(4, __LINE__, "", message)
#define enLog_Debug(message) enLog_To(5, __LINE__, "", message)
#define enLog_Trace(message) enLog_To(6, __LINE__, "", message)

#define enLog_PrintTo(target_uuid, message) enLog_To(0, __LINE__, target_uuid, message)
#define enLog_FatalTo(target_uuid, message) enLog_To(1, __LINE__, target_uuid, message)
#define enLog_ErrorTo(target_uuid, message) enLog_To(2, __LINE__, target_uuid, message)
#define enLog_WarnTo(target_uuid, message)  enLog_To(3, __LINE__, target_uuid, message)
#define enLog_InfoTo(target_uuid, message)  enLog_To(4, __LINE__, target_uuid, message)
#define enLog_DebugTo(target_uuid, message) enLog_To(5, __LINE__, target_uuid, message)
#define enLog_TraceTo(target_uuid, message) enLog_To(6, __LINE__, target_uuid, message)

#define enLog_Success(message) enLog_To(0, __LINE__, "", "✅ SUCCESS: " + message)
#define enLog_SuccessTo(target_uuid, message) enLog_To(0, __LINE__, target_uuid, "✅ SUCCESS: " + message)

#define enLog_GetLogtarget() \
    llLinksetDataRead("logtarget")

#define enLog_SetLogtarget(target) \
    llLinksetDataWrite("logtarget", target)
