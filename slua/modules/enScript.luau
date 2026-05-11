--!strict

local enConsole = require("enConsole")

local enScript = {}

function enScript.Stop(): ()
    enConsole.Print(`Script "{ll.GetScriptName()}" stopped`)
    ll.SetScriptState(ll.GetScriptName(), 0)
    ll.Sleep(1.0) -- give the simulator time to stop the script to be safe
    ll.ResetScript()
end

-- TODO: reimplement something like FEATURE_ENLOG_ENABLE_DELETE_OWNEDBYCREATOR and FEATURE_ENLOG_DISABLE_DELETE
function enScript.Delete(): ()
    if ll.GetInventoryCreator(ll.GetScriptName()) == ll.GetOwner() then
        enConsole.Error(`Script "{ll.GetScriptName()}" could not be deleted (owned by creator)`)
    else
        enConsole.Print(`Script "{ll.GetScriptName()}" deleted`)
        ll.RemoveInventory(ll.GetScriptName())
    end
    enScript.Stop()
end

-- TODO: reimplement something like FEATURE_ENLOG_ENABLE_DIE_OWNEDBYCREATOR and FEATURE_ENLOG_DISABLE_DIE
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

function enScript.Memory(): string
    return `{ll.GetUsedMemory()} B used, {ll.GetSPMaxMemory()} B max, {ll.GetMemoryLimit()} B limit, {ll.GetFreeMemory()} B free, gc_info()={gcinfo()}`
end

return enScript
