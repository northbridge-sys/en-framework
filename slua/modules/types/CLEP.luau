--!strict

--[[
Type definition for CLEP messages.
]]

local CLEP = {}
CLEP.__index = CLEP

type self = {
    metadata: {
        source: {
            link: number?,
            prim: uuid,
            script: string? -- if an enhanced messaging function ever appears that can guarantee a source script name, it may be used
        },
        key_name: string?,
        hash_algo: string?,
        sign_algo: "RSA" | "HMAC"?
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
export type Message = typeof(setmetatable({} :: self, CLEP))

function CLEP.new(
    metadata: {
        source: {
            link: number?,
            prim: uuid,
            script: string?
        },
        key_name: string?,
        hash_algo: string?,
        sign_algo: "RSA" | "HMAC"?
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
): Message
    local self = {metadata = metadata, payload = payload}
    return setmetatable(self, CLEP)
end

return CLEP
