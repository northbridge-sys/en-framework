--!strict

local enConsole = require("enConsole")

local enScript = {}

--[[
Stops the script.
]]
function enScript.Stop(): ()
    enConsole.Print(`Script "{ll.GetScriptName()}" stopped`)
    ll.SetScriptState(ll.GetScriptName(), false)
    ll.Sleep(1.0) -- give the simulator time to stop the script to be safe
    ll.ResetScript()
end

-- TODO: reimplement something like FEATURE_ENLOG_ENABLE_DELETE_OWNEDBYCREATOR and FEATURE_ENLOG_DISABLE_DELETE
--[[
Deletes the script and stops it.
Prints an error instead of deleting if the script is owned by its creator for safety.
]]
function enScript.Delete(): ()
    if ll.GetInventoryCreator(ll.GetScriptName()) == ll.GetOwner() then
        enConsole.Fatal(`Script "{ll.GetScriptName()}" could not be deleted (owned by creator)`)
    else
        enConsole.Print(`Script "{ll.GetScriptName()}" deleted`)
        ll.RemoveInventory(ll.GetScriptName())
    end
    enScript.Stop()
end

-- TODO: reimplement something like FEATURE_ENLOG_ENABLE_DIE_OWNEDBYCREATOR and FEATURE_ENLOG_DISABLE_DIE
--[[
Deletes or detaches the object the script is in.
Prints an error instead of deleting if the object is owned by the script's creator.
]]
function enScript.ObjectDie(): ()
    local outcome = "deleted"
    if ll.GetAttached() ~= 0 then
        outcome = `detached`
    end
    if ll.GetInventoryCreator(ll.GetScriptName()) == ll.GetOwner() then
        enConsole.Error(`Object could not be {outcome} (script owned by creator)`)
    elseif ll.GetAttached() then
        enConsole.Print(`Object {outcome}`)
        ll.DetachFromAvatar()
    else
        ll.Die()
    end
    enScript.Stop()
end

--[[
Returns a string with detailed memory information.
@return Memory debug string
]]
function enScript.Memory(): string
    return `{ll.GetUsedMemory()} B used, {ll.GetSPMaxMemory()} B max, {ll.GetMemoryLimit()} B limit, {ll.GetFreeMemory()} B free, gc_info()={gcinfo()}`
end

return enScript
