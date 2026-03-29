--!strict

local enTable = {}

--[[
Polyfill for table.extend until it shows up on main grid
]]
function enTable.Extend(a: {}, b: {}): {}
    table.move(b, 1, #b, #a + 1, a)
    return a
end

return enTable
