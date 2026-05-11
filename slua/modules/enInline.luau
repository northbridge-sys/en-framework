--!strict

local enInline = {}

--- Equivalent to Excel's IF() - if statement is true, return 2nd param, otherwise 3rd
function enInline.If(statement: boolean, true_string: string, false_string: string?): string
    if statement then return true_string
    else return false_string or "" end
end

function enInline.Plural(countable: number, s: string?): string
    if countable ~= 1 then return s or "s"
    else return "" end
end

return enInline
