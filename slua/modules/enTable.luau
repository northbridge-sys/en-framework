--!strict

local enTable = {}

function enTable.CountDictionary(t: {}): number
    local count = 0
    for _ in pairs(t) do
        count += 1
    end
    return count
end

return enTable
