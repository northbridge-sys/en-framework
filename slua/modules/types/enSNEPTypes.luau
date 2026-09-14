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

type SignatureStruct = {
    sign_algo: string,
    hash_algo: string,
    key_name: string,
    signature: string
}
export type Signature = typeof(setmetatable({} :: SignatureStruct, enSNEPTypes))

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

function enSNEPTypes.SignHMAC(key: HMACKey, payload: string, hash_algo: string?): Signature
    local self = {}
    self.sign_algo = "HMAC"
    self.hash_algo = hash_algo or "sha256"
    self.key_name = key.key_name
    local utime = os.time()
    self.signature = ll.HMAC(key.secret :: string, tostring(utime) .. payload, self.hash_algo)
    return setmetatable(self, enSNEPTypes)
end

function enSNEPTypes.SignRSA(key: RSAKeyPair, payload: string, hash_algo: string?): Signature
    local self = {}
    self.sign_algo = "RSA"
    self.hash_algo = hash_algo or "sha256"
    self.key_name = key.key_name
    local utime = os.time()
    self.signature = ll.SignRSA(key.private_key :: string, tostring(utime) .. payload, self.hash_algo)
    return setmetatable(self, enSNEPTypes)
end

return enSNEPTypes
