--!strict

local enInline = {}

--[[
Equivalent to Excel's IF() - if statement is true, return 2nd param, otherwise 3rd.
@param statement Any boolean
@param true_val Value to return if true
@param false_val Value to return if false
@return Either true_val or false_val
]]
function enInline.If(statement: boolean?, true_val: any?, false_val: any?): any?
    if statement then return true_val
    else
        return false_val
    end
end

--[[
Returns "s" or a provided string if a countable is not 1 (such that it would be considered a grammatically plural number).
@param countable Any number (or nil)
@param s Optional: "es", or some other string for the plural suffix
@return s, or no s
]]
function enInline.Plural(countable: number?, s: string?): string
    if not countable or countable ~= 1 then return s or "s"
    else
        return ""
    end
end

return enInline
