--!strict

local enEscape = {}

--- Escapes a string so that it may be safely used in a regex search (like for linkset data).
function enEscape.Regex(input: string): string
    local chars = {"\\", "^", "$", "*", "+", "?", ".", "(", ")", "|", "{", "}", "[", "]"}
    for i, char in chars do
        -- run llReplaceSubString on each possible character that needs to be escaped
        -- unfortunately Luau's string.gsub() uses some obtuse regex-like escape system that I failed to learn
        input = ll.ReplaceSubString(input, char, "", 0)
    end
    return input
end

return enEscape
