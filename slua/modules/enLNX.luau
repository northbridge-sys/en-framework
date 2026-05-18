--!strict

local enConsole: typeof(require("enConsole"))
local enEscape: typeof(require("enEscape"))

local enLNX = {
    _init = false
}

-- "constants"
enLNX.SCOPE = {
    LINKSET = "L",
    PRIM = "P",
    SCRIPT = "S"
}
enLNX._scriptname = ""
enLNX._primuuid = NULL_KEY

function enLNX.Init(dependency_enConsole: typeof(require("enConsole")), dependency_enEscape: typeof(require("enEscape"))): ()
    enConsole = dependency_enConsole
    enEscape = dependency_enEscape
    enLNX._init = true
end

function enLNX._Header(scope: string, linknum: number?, script: string?): string
    if scope == enLNX.SCOPE.SCRIPT then
        local key = ll.GetKey()
        if linknum then key = ll.GetLinkKey(linknum) end
        return tostring(key) .. "\n" .. (script or ll.GetScriptName()) .. "\n"
    elseif scope == enLNX.SCOPE.PRIM then
        local key = ll.GetKey()
        if linknum then key = ll.GetLinkKey(linknum) end
        return tostring(key) .. "\n\n"
    else
        return "\n\n"
    end
end

function enLNX.PairToPath(pair: string): {string}
    if pair == "" then return {} end
    local path = string.split(pair, "\n")
    table.remove(path) -- remove prim
    table.remove(path) -- remove script
    return path
end

function enLNX.Write(scope: string, path: {string}, data: any?, linknum: number?): boolean
    assert(enLNX._init, `Run enLNX.Init() first`)
    local value = ""
    if data ~= nil then value = lljson.slencode(data) end
    return ll.LinksetDataWrite(enLNX._Header(scope, linknum) .. table.concat(path, "\n"), value) ~= 0
end

function enLNX.Read(scope: string, path: {string}, linknum: number?, script: string?): any?
    assert(enLNX._init, `Run enLNX.Init() first`)
    local value = ll.LinksetDataRead(enLNX._Header(scope, linknum, script) .. table.concat(path, "\n"))
    if value and value ~= "" then
        local success, data = pcall(lljson.sldecode, value)
        if not success then
            -- not an empty datastore pair, but also not slencoded data
            enConsole.Warn(`Failed to read LNX data\nScope {scope}, link {linknum}, script "{script}", path ["{table.concat(path, `", "`)}"]: {value}\n{data}`)
            return nil
        end
        return data
    end
    return nil
end

function enLNX.Reset(scope: string, linknum: number?): (number, number)
    assert(enLNX._init, `Run enLNX.Init() first`)
    local result = ll.LinksetDataDeleteFound(`^{enEscape.Regex(enLNX._Header(scope, linknum))}.*$`, "")
    local deleted = tonumber(result[1])
    local denied = tonumber(result[2])
    if not deleted or not denied then return 0, 0 end
    return deleted, denied
end

function enLNX.Delete(scope: string, path: {string}, linknum: number?): boolean
    assert(enLNX._init, `Run enLNX.Init() first`)
    if ll.LinksetDataDeleteFound(`^{enEscape.Regex(enLNX._Header(scope, linknum) .. table.concat(path, "\n"))}$`, "")[1] == 1 then
        return true
    end
    return false
end

function enLNX.DeleteChildren(scope: string, path: {string}, linknum: number?): (number, number)
    assert(enLNX._init, `Run enLNX.Init() first`)
    local result = ll.LinksetDataDeleteFound(`^{enEscape.Regex(enLNX._Header(scope, linknum) .. table.concat(path, "\n"))}\n[^\n]*$`, "")
    local deleted = tonumber(result[1])
    local denied = tonumber(result[2])
    if not deleted or not denied then return 0, 0 end
    return deleted, denied
end

function enLNX.DeleteChildrenRecursive(scope: string, path: {string}, linknum: number?): (number, number)
    assert(enLNX._init, `Run enLNX.Init() first`)
    local result = ll.LinksetDataDeleteFound(`^{enEscape.Regex(enLNX._Header(scope, linknum) .. table.concat(path, "\n"))}\n.*$`, "")
    local deleted = tonumber(result[1])
    local denied = tonumber(result[2])
    if not deleted or not denied then return 0, 0 end
    return deleted, denied
end

function enLNX.Find(scope: string, path: {string}, start: number?, count: number?, linknum: number?): {}
    assert(enLNX._init, `Run enLNX.Init() first`)
    return ll.LinksetDataFindKeys(`^{enEscape.Regex(enLNX._Header(scope, linknum) .. table.concat(path, "\n"))}$`, start or 1, count or 0)
end

function enLNX.FindChildren(scope: string, path: {string}, start: number?, count: number?, linknum: number?): {}
    assert(enLNX._init, `Run enLNX.Init() first`)
    return ll.LinksetDataFindKeys(`^{enEscape.Regex(enLNX._Header(scope, linknum) .. table.concat(path, "\n"))}\n[^\n]*$`, start or 1, count or 0)
end

function enLNX.FindChildrenRecursive(scope: string, path: {string}, start: number?, count: number?, linknum: number?): {}
    assert(enLNX._init, `Run enLNX.Init() first`)
    return ll.LinksetDataFindKeys(`^{enEscape.Regex(enLNX._Header(scope, linknum) .. table.concat(path, "\n"))}\n.*$`, start or 1, count or 0)
end

function enLNX.Exists(scope: string, path: {string}, linknum: number?): boolean
    return enLNX.Find(scope, path) ~= {}
end

function enLNX.FindRegex(scope: string, regex: string, start: number?, count: number?, linknum: number?): {}
    assert(enLNX._init, `Run enLNX.Init() first`)
    return ll.LinksetDataFindKeys(`^{enEscape.Regex(enLNX._Header(scope, linknum))}{regex}$`, start or 1, count or 0)
end

function enLNX.DeleteRegex(scope: string, regex: string, linknum: number?): (number, number)
    assert(enLNX._init, `Run enLNX.Init() first`)
    local result = ll.LinksetDataDeleteFound(`^{enEscape.Regex(enLNX._Header(scope, linknum))}{regex}$`, "")
    local deleted = tonumber(result[1])
    local denied = tonumber(result[2])
    if not deleted or not denied then return 0, 0 end
    return deleted, denied
end

function enLNX._Purge(): ()
    assert(enLNX._init, `Run enLNX.Init() first`)
    local root = ll.GetLinkKey(0) -- use link 0 when single prim
    if ll.GetNumberOfPrims() > 1 then
        root = ll.GetLinkKey(1) -- use link 1 when multi prim
    end

    -- purge data pairs by prim and script
    local i = 1
    local keys = ll.LinksetDataFindKeys(`^[0-9a-fA-F-]{36}\n.*$`, i, 1)
    while keys ~= {} do
        local path = string.split(tostring(keys[1]), "\n")
        if touuid(path[1]) then
            -- this is either a prim-scope or script-scope pair, so check that the prim is still part of this linkset
            local path_prim = touuid(path[1]);
            if path_prim then
                local key_root = touuid(tostring(ll.GetObjectDetails(path_prim, {OBJECT_ROOT})[1]))
                if (not key_root) or key_root ~= root then
                    -- not in region or doesn't have the same root (so not the same linkset)
                    local results = ll.LinksetDataDeleteFound(`^{keys[1]}\n.*$`, "") -- delete all pairs scoped to this prim
                    enConsole.Trace(`Purged {results[1]} LNX pairs for prim {keys[1]} root {key_root}`)
                    i = 0 -- start search again (lazy)
                elseif path[2] ~= "" and path[1] == tostring(ll.GetKey()) and ll.GetInventoryType(path[2]) ~= INVENTORY_SCRIPT then
                    -- this is a script-scope pair in our prim, and the script is no longer in this prim, so delete it
                    local results = ll.LinksetDataDeleteFound(`^{keys[1]}\n{enEscape.Regex(path[2])}\n.*$`, "") -- delete all pairs scoped to this prim and missing script
                    enConsole.Trace(`Purged {results[1]} LNX pairs for script "{path[2]}" prim {keys[1]} root {key_root}`)
                    i = 0 -- start search again (lazy)
                end
            end
        end
        i = i + 1
        keys = ll.LinksetDataFindKeys(`^[0-9a-fA-F-]{36}\n.*$`, i, 1)
    end

    -- purge primuuid backups by linknum
    i = 1
    keys = ll.LinksetDataFindKeys(`^[0-9]*\n.*$`, i, 1)
    while keys ~= {} do
        local s_key = tostring(keys[1])
        if s_key then
            local path = string.split(s_key, "\n")
            local linknum = tonumber(path[1])
            if linknum and ll.GetNumberOfPrims() < linknum then
                ll.LinksetDataDelete(s_key)
                enConsole.Trace(`Purged backup pair for link {linknum}`)
                i = 0
            end
        end
        i = i + 1
        keys = ll.LinksetDataFindKeys(`^[0-9]*\n.*$`, i, 1)
    end
end

function enLNX._MigratePrim(old_prim_uuid: uuid): ()
    assert(enLNX._init, `Run enLNX.Init() first`)
    if not old_prim_uuid or old_prim_uuid == uuid(NULL_KEY) or old_prim_uuid == ll.GetKey() then return end
    enConsole.Debug(`Migrating LNX datastore for prim {old_prim_uuid} to prim {ll.GetKey()}`)
    local keys = ll.LinksetDataFindKeys(`^{enEscape.Regex(tostring(old_prim_uuid))}\n.*\n.*$`, 1, 1)
    while keys[1] do
        local s_old_key = tostring(keys[1])
        local old_key = string.split(s_old_key, "\n")
        local new_key = {}
        for index, value in old_key do
            new_key[index] = value
        end
        new_key[1] = tostring(ll.GetKey())
        ll.LinksetDataWrite(table.concat(new_key, "\n"), ll.LinksetDataRead(s_old_key))
        ll.LinksetDataDelete(s_old_key)
        enConsole.Trace(`LNX pair \{{table.concat(old_key, ",")}\} prim-migrated to \{{table.concat(new_key, ",")}\}`)
        keys = ll.LinksetDataFindKeys(`^{enEscape.Regex(tostring(old_prim_uuid))}\n.*\n.*$`, 1, 1)
    end
end

function enLNX._MigrateScript(old_script_name: string): ()
    assert(enLNX._init, `Run enLNX.Init() first`)
    if old_script_name == "" then return end
    enConsole.Debug(`Migrating LNX datastore for script "{old_script_name}"`)
    local keys = ll.LinksetDataFindKeys(`^{ll.GetKey()}\n{enEscape.Regex(old_script_name)}\n.*$`, 1, 1)
    while keys[1] do
        local s_old_key = tostring(keys[1])
        local old_key = string.split(s_old_key, "\n")
        local new_key = {}
        for index, value in old_key do
            new_key[index] = value
        end
        new_key[2] = ll.GetScriptName()
        ll.LinksetDataWrite(table.concat(new_key, "\n"), ll.LinksetDataRead(s_old_key))
        ll.LinksetDataDelete(s_old_key)
        enConsole.Trace(`LNX pair \{{table.concat(old_key, ",")}\} script-migrated to \{{table.concat(new_key, ",")}\}`)
        keys = ll.LinksetDataFindKeys(`^{ll.GetKey()}\n{enEscape.Regex(old_script_name)}\n.*$`, 1, 1)
    end
end

function enLNX._CheckScriptName(): ()
    if ll.GetScriptName() ~= enLNX._scriptname then
        enLNX._MigrateScript(enLNX._scriptname)
        enLNX._scriptname = ll.GetScriptName()
    end
end

function enLNX._CheckPrimUUID(): ()
    if enLNX._primuuid and enLNX._primuuid ~= NULL_KEY and ll.GetKey() ~= enLNX._primuuid then
        enLNX._MigratePrim(enLNX._primuuid)
        enLNX._primuuid = ll.GetKey()
        enLNX._BackupPrimUUID()
    end
end

function enLNX._BackupPrimUUID(): ()
    -- prim UUID is backed up by link number stored where prim uuid is typically stored in LNX pairs
    ll.LinksetDataWrite(`{ll.GetLinkNumber()}\n\nprimuuid`, tostring(ll.GetKey()))
end

function enLNX._RecallPrimUUID(): uuid?
    return touuid(ll.LinksetDataRead(`{ll.GetLinkNumber()}\n\nprimuuid`))
end

LLEvents:on("on_rez", enLNX._CheckPrimUUID)

LLEvents:on("changed", function(change: number): ()
    if bit32.btest(change, CHANGED_INVENTORY) then
        enLNX._CheckScriptName()
    end
    if bit32.btest(change, CHANGED_LINK) then
        enLNX._BackupPrimUUID()
        -- TODO: after a set time period, run Purge (to allow for relinking)
    end
end)

enLNX._scriptname = ll.GetScriptName() -- presume the script name did not change, so just reset it
enLNX._primuuid = enLNX._RecallPrimUUID() -- old prim uuid needs to be recovered from LNX backup
if enLNX._primuuid == NULL_KEY then
    -- we had no backup, so back it up now
    enLNX._primuuid = ll.GetKey()
    enLNX._BackupPrimUUID()
end
enLNX._CheckPrimUUID() -- if old prim uuid changed, that means we are a new copy (most likely shift-dragged but not necessarily), so this will migrate the prim

return enLNX
