local enDump = {}

--- Recursively dump a table to a string.
function enDump.Table(t: {}?): string
    return enDump._Table(t, 0)
end

function enDump._Table(t: {}?, level: number): string
 
    if typeof(t) ~= "table" then return tostring(t) end

    local out = ""

    if level ~= 0 then
        out ..= "\n"
    end

    out ..= string.rep("\t", level) .. "{\n"

    level = level + 1
    for key, value in pairs(t) do
        out ..= string.rep("\t", level) .. string.format("[%s] = ", key) .. enDump._Table(value, level) .. ",\n"
    end
    level = level - 1

    return out .. string.rep("\t", level) .. "}"
end

return enDump