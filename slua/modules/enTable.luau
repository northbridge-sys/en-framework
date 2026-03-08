--!strict

local enTable = {}

function enTable.Join(a: {}, b: {}): {}
    for i = 1, #b do
        a[#a + 1] = b[i]
    end
    return a
end

return enTable
