--!strict

local enPUMA = {
    SCOPE = {
        DESCRIPTION = 0x1,
        HOVERTEXT = 0x2
    }
}

function enPUMA._WriteTable(link: number, scope: number, puma: {[string]: string}): ()
    -- prioritize description, then hovertext, then name
    local puma_list = {} :: {string}
    for key, value in puma do
        table.append(puma_list, key, value)
    end
    local text = table.concat(puma_list, "~") .. "`"

    if bit32.btest(scope, enPUMA.SCOPE.DESCRIPTION) then
        ll.SetLinkPrimitiveParamsFast(link, {PRIM_DESC, "!~" .. string.sub(text, 1, 125)})
        text = string.sub(text, 126)
        if #text == 0 then return end
    end
    if bit32.btest(scope, enPUMA.SCOPE.HOVERTEXT) then
        ll.SetLinkPrimitiveParamsFast(link, {PRIM_TEXT, "!~" .. string.sub(text, 1, 252), vector(0, 0, 0), 0.0})
        text = string.sub(text, 253)
        if #text == 0 then return end
    end
    
    error(`PUMA length exceeded`)
end

--[[
Writes a pair to the PUMA datastore for a specified link number.
Warning: invalid keys and values return errors. If you encode user data into the value, either strip invalid chars ("~", "`", "|"), encode as base64/"base92"/etc., or catch errors.
@param key Name of pair
@param value Value of pair (nil to erase)
@param link Optional: Link number or LINK_* constant (default LINK_THIS)
@param scope Optional: Any combination of enPUMA.SCOPE.* constants (default DESCRIPTION & HOVERTEXT)
]]
function enPUMA.WritePair(key: string, value: any?, link: number?, scope: number?): ()
    assert(#key <= 16, `key exceeds 16 bytes: {key}`)

    -- Invalid character check
    for _, char in {"~", "`", "|"} do -- ~ is the list separator, ` is the terminator, and | is disallowed in names and descriptions
        -- TODO: I know there is a better way to do this, but lua's matches scare me
        assert(#string.split(key, char) == 1, `key contains invalid char: {char}: {key}`)
        if value then
            assert(#string.split(value, char) == 1, `value contains invalid char: {char}: {value}`)
        end
    end

    -- read PUMA from prim
    local puma = enPUMA.GetTable(ll.GetLinkKey(link or LINK_THIS))
    puma[key] = value
    enPUMA._WriteTable(link or LINK_THIS, scope or bit32.bor(enPUMA.SCOPE.DESCRIPTION, enPUMA.SCOPE.HOVERTEXT), puma)
end

--[[
Gets all PUMA data for a specified prim in the region as a dictionary table.
Returns an empty table if there is no data stored, or if the description is empty or non-compliant.
Throws an error if the prim is not found.
@param prim_uuid Optional: UUID of prim to read PUMA datastore of (default this prim)
@return dictionary table of all PUMA key-value pairs
]]
function enPUMA.GetTable(prim_uuid: uuid?): {}
    local details = ll.GetObjectDetails(prim_uuid or ll.GetKey(), {OBJECT_DESC, OBJECT_TEXT})
    assert(details and #details > 0, `Prim not found: {prim_uuid}`)

    local text = ""
    for i = 1, 2 do
        if string.sub(details[i], 1, 2) == "!~" and #details[i] > 2 then
            text ..= string.sub(details[i], 3)
            if string.sub(text, -1, -1) == "`" then
                -- end of array - don't read any additional fields
                i = 3
                text = string.sub(text, 1, -2)
            end
        end
    end
    if text == "" then return {} end
    local puma_list = string.split(text, "~")
    local puma = {}
    for i = 1, #puma_list, 2 do
        puma[puma_list[i]] = puma_list[i + 1]
    end
    return puma
end

--[[
Gets a specified key-value pair's value from the PUMA datastore of a specified prim in the region.
Returns nil if there is no value stored for this key, or if the description is empty or non-compliant.
Throws an error if the prim is not found.
@param key Pair key (name) to read
@param prim_uuid Optional: UUID of prim with PUMA datastore to read
@return value
]]
function enPUMA.ReadPair(key: string, prim_uuid: uuid?): string?
    local puma = enPUMA.GetTable(prim_uuid)
    return puma[key]
end

return enPUMA
