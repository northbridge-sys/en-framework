--!strict

local enTable = {}

--[[
Counts the number of pairs in a dictionary table.
@param t Any dictionary table
@result Number of pairs
]]
function enTable.CountDictionary(t: {}): number
    local count = 0
    for _ in pairs(t) do
        count += 1
    end
    return count
end

return enTable
