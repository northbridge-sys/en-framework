--!strict

--[[
Type definition for enCLEP messages.
]]

local enCLEPTypes = {}
enCLEPTypes.__index = enCLEPTypes

type self = {
    metadata: {
        source: {
            link: number?,
            prim: uuid,
            script: string? -- if an enhanced messaging function ever appears that can guarantee a source script name, it may be used
        },
        key_name: string?,
        hash_algo: string?,
        sign_algo: string?
    },
    payload: {
        utime: number,
        source: {
            region: string,
            prim: uuid,
            script: string
        },
        target: {
            link: number?,
            region: string?,
            prim: uuid?,
            script: string?
        },
        domain: string,
        id: uuid,
        method: {string},
        params: any?,
        result: any?
    }
}
export type Message = typeof(setmetatable({} :: self, enCLEPTypes))

function enCLEPTypes.NewMessage(
    data: self
): Message
    local self = data
    return setmetatable(self, enCLEPTypes)
end

return enCLEPTypes
