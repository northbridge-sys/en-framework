--!strict

local enEscape = require("enEscape")

local enConsole: typeof(require("enConsole"))

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

--[[
Mandatory initlaization function.
@param _enConsole enConsole
]]
function enLNX.Init(
    _enConsole: typeof(require("enConsole"))
): ()
    enConsole = _enConsole
    enLNX._init = true
end

function enLNX._Header(scope: string, linknum: number?, script: string?): string
    if scope == enLNX.SCOPE.SCRIPT then
        local key = ll.GetKey()
        if linknum then
            key = ll.GetLinkKey(linknum)
        end
        return tostring(key) .. "\n" .. (script or ll.GetScriptName()) .. "\n"
    elseif scope == enLNX.SCOPE.PRIM then
        local key = ll.GetKey()
        if linknum then
            key = ll.GetLinkKey(linknum)
        end
        return tostring(key) .. "\n\n"
    else
        return "\n\n"
    end
end

--[[
Converts a linkset data pair name into an LNX path.
(Splits string and removes LNX prim/script headers.)
@param pair Linkset data pair name
@return Table (list) of path elements
]]
function enLNX.PairToPath(pair: string): {string}
    if pair == "" then return {} end
    local path = string.split(pair, "\n")
    table.remove(path) -- remove prim
    table.remove(path) -- remove script
    return path
end

--[[
Converts an LNX scope, path, link number, and script name into a linkset data pair name.
@param scope Any enLNX.SCOPE.* constant
@param path LNX path
@param linknum Optional: link number for prim and script scopes (default LINK_THIS)
@param script Optional: script name for script scopes (default this script)
@return Linkset data pair name
]]
function enLNX.PathToPair(scope: string, path: {string}, linknum: number?, script: string?): string
    return enLNX._Header(scope, linknum, script) .. table.concat(path, "\n")
end

--[[
Writes to an LNX path.
@param scope Any enLNX.SCOPE.* constant
@param path LNX path
@param data Any value, or nil
@param linknum Optional: link number for prim and script scopes (default LINK_THIS)
]]
function enLNX.Write(scope: string, path: {string}, data: any?, linknum: number?): boolean
    assert(enLNX._init, `Run enLNX.Init() first`)
    local value = ""
    if data ~= nil then
        value = lljson.slencode(data)
    end
    return ll.LinksetDataWrite(enLNX.PathToPair(scope, path, linknum), value) ~= 0
end

--[[
Reads a specified LNX path.
@param scope Any enLNX.SCOPE.* constant
@param path LNX path
@param linknum Optional: link number for prim and script scopes (default LINK_THIS)
@param script Optional: script for script scope (default this script)
]]
function enLNX.Read(scope: string, path: {string}, linknum: number?, script: string?): any?
    assert(enLNX._init, `Run enLNX.Init() first`)
    local value = ll.LinksetDataRead(enLNX.PathToPair(scope, path, linknum, script))
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

--[[
Resets the LNX datastore for a specified scope.
@param scope Any enLNX.SCOPE.* constant
@param linknum Optional: link number for prim and script scopes (default LINK_THIS)
]]
function enLNX.Reset(scope: string, linknum: number?): (number, number)
    assert(enLNX._init, `Run enLNX.Init() first`)
    local result = ll.LinksetDataDeleteFound(`^{enEscape.Regex(enLNX._Header(scope, linknum))}.*$`, "")
    local deleted = tonumber(result[1])
    local denied = tonumber(result[2])
    if not deleted or not denied then return 0, 0 end
    return deleted, denied
end

--[[
Deletes a specified path from the specified LNX datastore scope.
@param scope Any enLNX.SCOPE.* constant
@param path LNX path
@param linknum Optional: link number for prim and script scopes (default LINK_THIS)
@return Any LINKSETDATA_* constant
]]
function enLNX.Delete(scope: string, path: {string}, linknum: number?): number
    assert(enLNX._init, `Run enLNX.Init() first`)
    return ll.LinksetDataDelete(enLNX.PathToPair(scope, path, linknum))
end

--[[
Deletes all children of a specified path.
@param scope Any enLNX.SCOPE.* constant
@param path LNX path of parent
@param linknum Optional: link number for prim and script scopes (default LINK_THIS)
@param recursive Optional: if true, all children are recursively deleted; if false, only one level down
@return number of deleted pairs, number of pairs that could not be deleted
]]
function enLNX.DeleteChildren(scope: string, path: {string}, linknum: number?, recursive: boolean?): (number, number)
    assert(enLNX._init, `Run enLNX.Init() first`)
    local recurse = ".*"
    if recursive then
        recurse = "[^\n]*"
    end
    local result = ll.LinksetDataDeleteFound(`^{enEscape.Regex(enLNX.PathToPair(scope, path, linknum))}\n{recurse}$`, "")
    local deleted = tonumber(result[1])
    local denied = tonumber(result[2])
    if not deleted or not denied then return 0, 0 end
    return deleted, denied
end

--[[
Returns all pairs matching a specified scope and path, plus an optional regex suffix.
If the suffix isn't provided, this will only return the provided path (1 result), but is much more memory efficient than testing its existence by reading it.
@param scope Any enLNX.SCOPE.* constant
@param path LNX path of parent (or target if no suffix)
@param start Optional: start index of returned range
@param count Optional: count of returned range
@param linknum Optional: link number for prim and script scopes (default LINK_THIS)
@param suffix Optional: regex suffix for searching children
@return Table of linkset data pair names (see enLNX.PairToPath)
]]
function enLNX.Find(scope: string, path: {string}, start: number?, count: number?, linknum: number?, suffix: string?): {string}
    assert(enLNX._init, `Run enLNX.Init() first`)
    return ll.LinksetDataFindKeys(`^{enEscape.Regex(enLNX.PathToPair(scope, path, linknum))}{suffix or ""}$`, start or 1, count or 0)
end

--[[
Returns all direct (first-level) children of a specified scope and path.
@param scope Any enLNX.SCOPE.* constant
@param path LNX path of parent
@param start Optional: start index of returned range
@param count Optional: count of returned range
@param linknum Optional: link number for prim and script scopes (default LINK_THIS)
@return Table of linkset data pair names (see enLNX.PairToPath)
]]
function enLNX.FindChildren(scope: string, path: {string}, start: number?, count: number?, linknum: number?): {string}
    return enLNX.Find(scope, path, start, count, linknum, "[^\n]*")
end

--[[
Returns all recursive children of a specified scope and path.
@param scope Any enLNX.SCOPE.* constant
@param path LNX path of parent
@param start Optional: start index of returned range
@param count Optional: count of returned range
@param linknum Optional: link number for prim and script scopes (default LINK_THIS)
@return Table of linkset data pair names (see enLNX.PairToPath)
]]
function enLNX.FindChildrenRecursive(scope: string, path: {string}, start: number?, count: number?, linknum: number?): {string}
    return enLNX.Find(scope, path, start, count, linknum, ".*")
end

--[[
Tests to see if a specified scope and path exist.
@param scope Any enLNX.SCOPE.* constant
@param path LNX path
@param linknum Optional: link number for prim and script scopes (default LINK_THIS)
@return true if exists, false if not
]]
function enLNX.Exists(scope: string, path: {string}, linknum: number?): boolean
    return next(enLNX.Find(scope, path, 1, 1, linknum)) ~= nil
end

--[[
Finds linkset data pair key names that match the specified regex-formatted string, with a header automatically prepended for a specified scope.
@param scope Any enLNX.SCOPE.* constant
@param regex Any regex-formatted string that defines the path section of the linkset data pair name
@param start Optional: start index of returned range
@param count Optional: count of returned range
@param linknum Optional: link number for prim and script scopes (default LINK_THIS)
@return Table of linkset data pair names (see enLNX.PairToPath)
]]
function enLNX.FindRegex(scope: string, regex: string, start: number?, count: number?, linknum: number?): {string}
    assert(enLNX._init, `Run enLNX.Init() first`)
    return ll.LinksetDataFindKeys(`^{enEscape.Regex(enLNX._Header(scope, linknum))}{regex}$`, start or 1, count or 0)
end

--[[
Deletes linkset data pairs that match a specified regex-formatted string, with a header automatically prepended for a specified scope.
@param scope Any enLNX.SCOPE.* constant
@param regex Any regex-formatted string that defines the path section of the linkset data pair name
@param linknum Optional: link number for prim and script scopes (default LINK_THIS)
@return number of deleted pairs, number of pairs that could not be deleted
]]
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
    while next(keys) ~= nil do
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
    while next(keys) ~= nil do
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
    if not old_prim_uuid or old_prim_uuid == uuid(NULL_KEY) or old_prim_uuid == ll.GetKey() then return end
    if enConsole then
        enConsole.Debug(`Migrating LNX datastore for prim {old_prim_uuid} to prim {ll.GetKey()}`)
    end
    local keys = ll.LinksetDataFindKeys(`^{enEscape.Regex(tostring(old_prim_uuid))}\n.*\n.*$`, 1, 1)
    while keys[1] do
        local s_old_key = tostring(keys[1])
        local old_key = string.split(s_old_key, "\n")
        local new_key = table.clone(old_key)
        new_key[1] = tostring(ll.GetKey()) -- replace prim uuid element of lsd key
        ll.LinksetDataWrite(table.concat(new_key, "\n"), ll.LinksetDataRead(s_old_key))
        ll.LinksetDataDelete(s_old_key)
        if enConsole then
            enConsole.Trace(`LNX pair \{{table.concat(old_key, ",")}\} prim-migrated to \{{table.concat(new_key, ",")}\}`)
        end
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
        local new_key = table.clone(old_key)
        new_key[2] = ll.GetScriptName() -- replace script name element of lsd key
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
enLNX._primuuid = enLNX._RecallPrimUUID() or ll.GetKey() -- old prim uuid needs to be recovered from LNX backup
if enLNX._primuuid == NULL_KEY then
    -- we had no backup, so back it up now
    enLNX._primuuid = ll.GetKey()
    enLNX._BackupPrimUUID()
end
enLNX._CheckPrimUUID() -- if old prim uuid changed, that means we are a new copy (most likely shift-dragged but not necessarily), so this will migrate the prim

return enLNX
