--!strict

--[[
Type definitions for enSNEP keys and signatures.
]]

local enSNEPTypes = {}
enSNEPTypes.__index = enSNEPTypes

type HMACKeyStruct = {
    sym: boolean,
    key_name: string,
    secret: string
}
export type HMACKey = typeof(setmetatable({} :: HMACKeyStruct, enSNEPTypes))

type RSAKeyPairStruct = {
    sym: boolean,
    key_name: string,
    public_key: string?,
    private_key: string
}
export type RSAKeyPair = typeof(setmetatable({} :: RSAKeyPairStruct, enSNEPTypes))

type RSAPublicKeyStruct = {
    key_name: string,
    public_key: string
}
export type RSAPublicKey = typeof(setmetatable({} :: RSAPublicKeyStruct, enSNEPTypes))

function enSNEPTypes.NewHMACKey(key_name: string, secret: string): HMACKey
    local self = {}
    self.sym = true
    self.key_name = key_name
    self.secret = secret
    return setmetatable(self, enSNEPTypes)
end

function enSNEPTypes.NewRSAKeyPair(key_name: string, private_key: string, public_key: string?): RSAKeyPair
    local self = {}
    self.sym = false
    self.key_name = key_name
    self.public_key = public_key
    self.private_key = private_key
    return setmetatable(self, enSNEPTypes)
end

function enSNEPTypes.NewRSAPublicKey(key_name: string, public_key: string): RSAPublicKey
    local self = {}
    self.sym = false
    self.key_name = key_name
    self.public_key = public_key
    return setmetatable(self, enSNEPTypes)
end

return enSNEPTypes
