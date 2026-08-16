--!strict

--[[
Type definitions for enSNEP keys and signatures.
]]

local enSNEPTypes = {}
enSNEPTypes.__index = enSNEPTypes

type KeyType = {
    key_name: string,
    shared_key: string?, -- only required for HMAC
    public_key: string?, -- only required for RSA validation
    private_key: string?, -- only required for RSA signing
}
export type Key = typeof(setmetatable({} :: KeyType, enSNEPTypes))

type SignatureType = {
    sign_algo: string,
    hash_algo: string,
    key_name: string,
    signature: string
}
export type Signature = typeof(setmetatable({} :: SignatureType, enSNEPTypes))

function enSNEPTypes.NewRSA(key_name: string, public_key: string?, private_key: string?): Key
    local self = {}
    self.key_name = key_name
    self.public_key = public_key
    self.private_key = private_key
    return setmetatable(self, enSNEPTypes)
end

function enSNEPTypes.NewHMAC(key_name: string, shared_key: string): Key
    local self = {}
    self.key_name = key_name
    self.shared_key = shared_key
    return setmetatable(self, enSNEPTypes)
end

function enSNEPTypes._NewSignature(sign_algo: string, hash_algo: string, key: Key, payload: string): Signature
    local self = {}
    self.sign_algo = sign_algo
    self.hash_algo = hash_algo
    self.key_name = key.key_name
    local utime = os.time()
    if self.sign_algo == "RSA" then
        self.signature = ll.SignRSA(key.private_key :: string, tostring(utime) .. payload, hash_algo)
    else
        self.signature = ll.HMAC(key.shared_key :: string, tostring(utime) .. payload, hash_algo)
    end
    return setmetatable(self, enSNEPTypes)
end

return enSNEPTypes
