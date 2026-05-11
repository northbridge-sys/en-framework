--!strict

local enStop = {}

function enStop._Check(): ()
    if tonumber(ll.LinksetDataRead("stop")) > 0 then
        print(`Script "{ll.GetScriptName()} stopped due to stop flag`)
        ll.SetScriptState(ll.GetScriptName(), 0)
        ll.Sleep(1.0)
        ll.ResetScript()
    end
end

LLEvents:on("on_rez", enStop._Check)

return enStop
