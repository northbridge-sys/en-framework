--!strict

local enStop = {}

function enStop.Check(pair_name: string?): () -- note: any non-string parameter is ignored, since this is also triggered by on_rez(integer start_param)
    if not pair_name or typeof(pair_name) ~= "string" then pair_name = "stop" end
    if tonumber(ll.LinksetDataRead(pair_name)) or 0 > 0 then
        print(`Script "{ll.GetScriptName()}" stopped due to "{pair_name :: string}" flag`)
        ll.SetScriptState(ll.GetScriptName(), 0)
        ll.Sleep(1.0)
        ll.ResetScript()
    end
end

LLEvents:on("on_rez", enStop.Check)

return enStop
