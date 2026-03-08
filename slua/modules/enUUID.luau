--!strict

local enUUID = {}

--- Determines if a UUID exists in this region.
-- @param input Any UUID.
-- @result true if it exists, false otherwise.
function enUUID.IsInRegion(input: uuid): boolean
    -- is it an avatar?
    if enUUID.IsAvatarInRegion(input) then
        return true
    end

    -- otherwise, say if it is a prim
    return enUUID.IsPrimInRegion(input)
end

--- Determines if a uuid is an avatar that exists in this region.
-- @param input Any uuid.
-- @result true if it is an avatar in this region, false otherwise.
function enUUID.IsAvatarInRegion(input: uuid): boolean
    -- is the input nil? if so, return false
    if not input then
        return false
    end

    -- does the input resolve to an avatar? if not, return false
    if ll.GetAgentSize(input) == ZERO_VECTOR then
        return false
    end

    return true
end

--- Determines if a string is a valid UUID of a prim that exists in this region.
-- @param input Any string.
-- @result true if it is a prim in this region, false otherwise.
function enUUID.IsPrimInRegion(input: uuid): boolean
    -- is the input nil? if so, return false
    if not input then
        return false
    end

    -- do the uuid's details resolve?
    local details = ll.GetObjectDetails(input, {OBJECT_OWNER})
    if #details == 0 then
        -- uuid doesn't exist in this region
        return false
    end

    -- does the uuid resolve to an avatar?
    if details[1] == input then
        -- uuid points to an avatar (owner matches uuid)
        return false
    end
    return true
end

return enUUID
