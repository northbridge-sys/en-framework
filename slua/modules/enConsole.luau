--!strict
local enCLEPTypes = require("@en-framework/types/enCLEPTypes")
local enSNEPTypes = require("@en-framework/types/enSNEPTypes")

--[[
The enConsole module is a logging library with support for directing logs to another script as necessary at runtime.
By default, it sends all logs of type Success, Print, Fatal, Error, Warn, or Info to the owner.
The owner can change the log level by changing the "loglevel" linkset data pair to the appropriate enConsole.LEVEL.* constant (0-6).
This module also passes any logs back via the callbacks_log function passed with enConsole.Init() so you can record them manually elsewhere.
If enCLEP, enListen, enSNEP, and a debug secret are passed into enConsole.Init(...), the module will allow third-party objects to capture logs.
This can only be done if the object negotiates a connection with a SNEP-signed CLEP message using the same secret.
LNX is not used to avoid a cyclic dependency.
]]

local enCLEP: typeof(require("@en-framework/enCLEP"))
local enListen: typeof(require("@en-framework/enListen"))
local enSNEP: typeof(require("@en-framework/enSNEP"))

local enConsole = {
    _snep_key = nil :: enSNEPTypes.RSAKeyPair|enSNEPTypes.HMACKey?,
    _debugger = nil :: uuid?,
    _callbacks = {
        log = nil :: (message: string, message_level: number, object_level: number, func_name: string, line: number, target_uuid: uuid?) -> ()?
    },
    LEVEL = {
        Print = 0,
        Fatal = 1,
        Error = 2,
        Warn = 3,
        Info = 4,
        Debug = 5,
        Trace = 6
    }
}

function enConsole._clep_message(
    clep: enCLEPTypes.Message
): ()
    if clep.metadata.key_name ~= "enConsole" then return end
    if clep.payload.method[1] == "Debugger" then
        if clep.payload.method[2] == "Enroll" then
            enConsole._debugger = clep.payload.source.prim
            enConsole.Debug(`Enrolled as debugger: {clep.payload.source.prim}`)
        elseif clep.payload.method[2] == "Unenroll" then
            enConsole._debugger = nil
            enConsole.Debug(`Unenrolled as debugger: {clep.payload.source.prim}`)
        end
    end
end

--[[
Initializes enConsole.
@param _enCLEP Optional: enCLEP (required for debug log routing support)
@param _enListen Optional: enListen (required for debug log routing support)
@param _enSNEP Optional: enSNEP (required for debug log routing support)
@param debug_secret Optional: Secret used for HMAC signing (required for debug log routing support)
@param callback_log Optional: Function to call when a message has been logged
]]
function enConsole.Init(
    _enCLEP: typeof(enCLEP),
    _enListen: typeof(enListen),
    _enSNEP: typeof(enSNEP),
    debug_secret: string?,
    callback_log: typeof(enConsole._callbacks.log)
): ()
    enCLEP = _enCLEP
    enListen = _enListen
    enSNEP = _enSNEP
    enConsole._callbacks.log = callback_log
    if enCLEP and enSNEP and debug_secret then
        enCLEP.Init(enListen, enSNEP, enConsole.Log)
        enCLEP.ListenChat("enConsole", false, enConsole._clep_message)
        enConsole._snep_key = enSNEPTypes.NewHMACKey("enConsole", debug_secret)
        enSNEP.Enroll(enConsole._snep_key :: enSNEPTypes.HMACKey)
        enConsole.Debug("enConsole initialized with debug log routing")
    else
        enConsole.Debug("enConsole initialized without debug log routing")
    end
end

--[[
Gets current loglevel as a number.
@return Current loglevel
]]
function enConsole.GetLoglevel(): number
    local lsd_level = tonumber(ll.LinksetDataRead("loglevel"))
    if lsd_level and lsd_level ~= 0 then
        return lsd_level
    end
    return 4 -- default Info
end

--[[
Generic logging function. Requires a numeric loglevel.
Use .Trace, .Debug, .Info, .Warn, .Error, .Fatal, or .Success, which call this function, instead for most cases.
@param level Loglevel number of message
@param message String to pass to log
@param target_uuid Optional: log message is sent to a specific UUID on channel 0 instead of printed to the owner
]]
function enConsole.Log(level: number, message: string, target_uuid: uuid?): ()
    local func_name, line = debug.info(3, "nl")
    local lsd_level = enConsole.GetLoglevel()
    if enConsole._callbacks.log then
        -- run callback_log
        enConsole._callbacks.log(message, level, lsd_level, func_name, line, target_uuid)
    end
    local memory_used_pct = string.format("%.2f", 100.0 * ll.GetUsedMemory() / ll.GetMemoryLimit())
    if enConsole._debugger then
        -- send via CLEP to registered debugger
        enCLEP.Send(
            enConsole._snep_key,
            {prim = enConsole._debugger},
            "enConsole",
            {"Log"},
            {
                message = message,
                level = level,
                lsd = lsd_level,
                func = func_name,
                line = line,
                target = target_uuid,
                mem = memory_used_pct
            },
            nil,
            nil,
            nil,
            true
        )
    end
    if lsd_level >= level then
        if lsd_level >= 5 then
            local short_time = string.sub(ll.GetTimestamp(), 12, 22)
            local uuid_head = string.sub(tostring(ll.GetKey()), 1, 4)
            local script_name = ll.GetScriptName()
            message = `🔽 [{short_time}] ({uuid_head} {memory_used_pct}%) "{script_name}" {func_name} @ {line}\n` .. message
        end
        if target_uuid then
            -- we are targeting a specific avatar for this log as called
            ll.RegionSayTo(target_uuid, 0, message)
            return
        end
        -- just send to owner
        print(message)
    end
end

--[[
Prints "✅ SUCCESS: " and the message to the log at the mandatory print loglevel.

@param 
]]
function enConsole.Success(message: string, target_uuid: uuid?): ()
    enConsole.Log(enConsole.LEVEL.Print, "✅ SUCCESS: " .. message, target_uuid)
end

function enConsole.Print(message: string, target_uuid: uuid?): ()
    enConsole.Log(enConsole.LEVEL.Print, message, target_uuid)
end

function enConsole.Fatal(message: string, target_uuid: uuid?): ()
    enConsole.Log(enConsole.LEVEL.Fatal, "🛑 FATAL ERROR: " .. message, target_uuid)
end

function enConsole.Error(message: string, target_uuid: uuid?): ()
    enConsole.Log(enConsole.LEVEL.Error, "❌ ERROR: " .. message, target_uuid)
end

function enConsole.Warn(message: string, target_uuid: uuid?): ()
    enConsole.Log(enConsole.LEVEL.Warn, "🚩 WARNING: " .. message, target_uuid)
end

function enConsole.Info(message: string, target_uuid: uuid?): ()
    enConsole.Log(enConsole.LEVEL.Info, "💬 " .. message, target_uuid)
end

function enConsole.Debug(message: string, target_uuid: uuid?): ()
    enConsole.Log(enConsole.LEVEL.Debug, "🪲 " .. message, target_uuid)
end

function enConsole.Trace(message: string, target_uuid: uuid?): ()
    enConsole.Log(enConsole.LEVEL.Trace, "🚦 " .. message, target_uuid)
end

return enConsole
