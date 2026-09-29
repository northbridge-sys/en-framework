--!strict

--[[
The enStop module stops the script if one of the following is true:
    - on_rez, the "stop" linkset data value is > 0
    - on calling enStop.Check(), the "stop" linkset data value is > 0
    - on calling enStop.Check("foo"), the foo linkset data value is > 0
This module doesn't use enLNX because it is self-contained (no dependencies). See enLNX.PathToPair(...) if LNX support is needed.
]]

local enStop = {}

function enStop.Check(pair_name: string?): () -- note: any non-string parameter is ignored, since this is also triggered by on_rez(integer start_param)
    if not pair_name or typeof(pair_name) ~= "string" then
        pair_name = "stop"
    end
    if pair_name and tonumber(ll.LinksetDataRead(pair_name)) or 0 > 0 then
        print(`Script "{ll.GetScriptName()}" stopped due to "{pair_name :: string}" flag`)
        ll.SetScriptState(ll.GetScriptName(), false)
        ll.Sleep(1.0)
        ll.ResetScript()
    end
end

LLEvents:on("on_rez", enStop.Check)

return enStop
