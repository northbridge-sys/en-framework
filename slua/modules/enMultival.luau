--[[
enMultival is a helper module for specific situations where multivals are used.
]]

local enMultival = {}

--[[
Returns true if the multival passed in consists only of a single nil.
]]
function enMultival.IsOnlyNil(...: any?): boolean
    -- note from https://benaiah.me/posts/everything-you-didnt-want-to-know-about-lua-multivals/
    -- multivals consider nil to be a distinct value
    -- typically it's easier to manipulate multivals by packing them into a table with {...}
    -- once you pack them into a table, the value is effectively lost (since tables can't have nils)
    -- so to check if the only result we got back was nil, we need to do it this way
    local multival_count = select("#", ...)
    if multival_count == 1 and select(multival_count, ...) == nil then
        -- we only got nil back
        -- this is a special case, such as an enAsync timeout
        return true
    end
    return false
end

return enMultival
