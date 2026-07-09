--!strict

local enConsole = require("@en-framework/enConsole")
local enPUMA = require("@en-framework/enPUMA")

local function main()
    enConsole.Info("enPUMA test writing")
    enPUMA.WritePair(LINK_THIS, "test1", "value for test1")
    enPUMA.WritePair(LINK_THIS, "test2", "~value for test2")
    enPUMA.WritePair(LINK_THIS, "test3", "|value for test3")

    enConsole.Info("enPUMA test reading")
    for _, key in {"test1", "test2", "test3"} do
        local value = enPUMA.ReadPair(ll.GetLinkKey(LINK_THIS), key)
        enConsole.Info(`{key} = "{value}"`)
        assert(string.sub(value or "", -5, -1), `enPUMA test failed on {key} read`)
    end

    enConsole.Info("enPUMA test erasing")
    enPUMA.WritePair(LINK_THIS, "test1")
    enPUMA.WritePair(LINK_THIS, "test2")
    enPUMA.WritePair(LINK_THIS, "test3")

    enConsole.Info("enPUMA test checking")
    for _, key in {"test1", "test2", "test3"} do
        local value = enPUMA.ReadPair(ll.GetLinkKey(LINK_THIS), key)
        assert(not value, `enPUMA test failed on {key} check`)
    end

    enConsole.Success("enPUMA test complete")
end

main()
