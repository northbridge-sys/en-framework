--!strict

local enPretty = {}

--- Avatar UUID prettifier.
-- @param avatar_uuid avatar UUID
-- @return avatar_uuid, quoted with a parenthetical rich link to their profile
function enPretty.Avatar(avatar_uuid: uuid): string
    return `secondlife:///app/agent/{avatar_uuid}/username ({avatar_uuid})`
end

--- Group UUID prettifier.
-- @param group_uuid group UUID
-- @return group_uuid, quoted with a parenthetical rich link to its about page
function enPretty.Group(group_uuid: uuid): string
    return `secondlife:///app/group/{group_uuid}/about ({group_uuid})`
end

--- Prim UUID prettifier.
-- @param prim_uuid prim UUID
-- @return prim_uuid, quoted with a parenthetical name and position, if it is in the same region
function enPretty.Prim(prim_uuid: uuid): string
    local details = ll.GetObjectDetails(prim_uuid, {OBJECT_NAME, OBJECT_POS})
    local vec = tovector(details[2])
    if #details == 0 or not vec then
        return `prim not in region ({prim_uuid})`
    end
    return `"{details[1]}" at {enPretty.Vector(vec, 3)} ({prim_uuid})`
end

--- Vector prettifier.
-- @param value vector
-- @param decimals optional number of digits after period, defaults to 4 (0.0001)
-- @return CSV vector as string, e.g. "0.1234, 0.1234, 0.1234"
function enPretty.Vector(value: vector, decimals: number?): string
    local format = "%.4f"
    if decimals then
        format = `%.{tostring(decimals)}f`
    end
    return `{string.format(format, value.x)}, {string.format(format, value.y)}, {string.format(format, value.z)}`
end

return enPretty
