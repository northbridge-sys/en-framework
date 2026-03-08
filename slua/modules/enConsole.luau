--!strict

local enConsole = {
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

local enUUID = require("enUUID")

function enConsole.GetLoglevel(): number
    local lsd_level = tonumber(ll.LinksetDataRead("loglevel"))
    if lsd_level and lsd_level ~= 0 then
        return lsd_level
    end
    return 4 -- TODO: is there some way we can do a macro so this default can be set per script...?
end

function enConsole._Log(message: string, level: number?, target_uuid: uuid?): ()
    local lsd_level = enConsole.GetLoglevel()
    if lsd_level >= (level or 4) then
        if lsd_level >= 5 then
            local short_time = string.sub(ll.GetTimestamp(), 12, 22)
            local memory_used_pct = string.format("%.2f", 100.0 * ll.GetUsedMemory() / ll.GetMemoryLimit())
            local uuid_head = string.sub(tostring(ll.GetKey()), 1, 4)
            local script_name = ll.GetScriptName()
            local func_name, line = debug.info(3, "nl")
            message = `🔽 [{short_time}] ({uuid_head} {memory_used_pct}%) "{script_name}" {func_name} @ {line}\n` .. message
        end
        if target_uuid and enUUID.IsAvatarInRegion(target_uuid) then
            -- we are targeting a specific avatar for this log as called, so do that instead of any external logging
            ll.RegionSayTo(target_uuid, 0, message)
            return
        end
        local logtarget = touuid(ll.LinksetDataRead("logtarget"))
        if logtarget then
            -- we have an external logtarget, so logs are being sent elsewhere
            if enUUID.IsAvatarInRegion(logtarget) then
                -- external logging to avatar
                ll.RegionSayTo(logtarget, 0, message)
                return
            elseif enUUID.IsPrimInRegion(logtarget) then
                -- external logging to prim, so we need to also read logchannel
                local logchannel = tonumber(ll.LinksetDataRead("logchannel"))
                if (not logchannel) or logchannel == 0 then
                    -- need logchannel, so revert to default ll.OwnerSay() method
                    ll.OwnerSay("logtarget set to prim but logchannel not set:\n" .. message)
                else
                    -- external logging to prim logtarget via logchannel
                    ll.RegionSayTo(logtarget, logchannel, message)
                end
                return
            end
        end
        -- external logging is not enabled, so just send to owner
        ll.OwnerSay(message)
    end
end

function enConsole.Success(message: string, target_uuid: uuid?): ()
    enConsole._Log("✅ SUCCESS: " .. message, enConsole.LEVEL.Print, target_uuid)
end

function enConsole.Print(message: string, target_uuid: uuid?): ()
    enConsole._Log(message, enConsole.LEVEL.Print, target_uuid)
end

function enConsole.Fatal(message: string, target_uuid: uuid?): ()
    enConsole._Log("🛑 FATAL ERROR: " .. message, enConsole.LEVEL.Fatal, target_uuid)
end

function enConsole.Error(message: string, target_uuid: uuid?): ()
    enConsole._Log("❌ ERROR: " .. message, enConsole.LEVEL.Error, target_uuid)
end

function enConsole.Warn(message: string, target_uuid: uuid?): ()
    enConsole._Log("🚩 WARNING: " .. message, enConsole.LEVEL.Warn, target_uuid)
end

function enConsole.Info(message: string, target_uuid: uuid?): ()
    enConsole._Log("💬 " .. message, enConsole.LEVEL.Info, target_uuid)
end

function enConsole.Debug(message: string, target_uuid: uuid?): ()
    enConsole._Log("🪲 " .. message, enConsole.LEVEL.Debug, target_uuid)
end

function enConsole.Trace(message: string, target_uuid: uuid?): ()
    enConsole._Log("🚦 " .. message, enConsole.LEVEL.Trace, target_uuid)
end

return enConsole
