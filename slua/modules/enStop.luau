--!strict

local enStop = {}

function enStop.Check(pair_name: string?): ()
    pair_name = pair_name or "stop"
    if tonumber(ll.LinksetDataRead(pair_name :: string)) or 0 > 0 then
        print(`Script "{ll.GetScriptName()}" stopped due to "{pair_name :: string}" flag`)
        ll.SetScriptState(ll.GetScriptName(), 0)
        ll.Sleep(1.0)
        ll.ResetScript()
    end
end

LLEvents:on("on_rez", enStop.Check)

return enStop
