--!strict

local enEscape = {}

--- Escapes a string so that it may be safely used in a regex search (like for linkset data).
-- This uses the regex charset used by LSL/SLua functions... I think.
function enEscape.Regex(input: string): string
    local chars = {"\\", "%^", "%$", "%*", "%+", "%?", "%.", "%(", "%)", "|", "%{", "%}", "%[", "%]"}
    for i = 1, #chars do
        input = string.gsub(input, chars[i], "\\" .. chars[i])
    end
    return input
end

return enEscape
