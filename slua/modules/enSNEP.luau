--!strict

local enSNEP = {}
enSNEP.__index = enSNEP

-- SNEPKey type definition

-- Defines the enSNEPKey object.
-- This is where RPC signing keys for RSA/HMAC are stored.
-- TODO: Split this into HMAC and RSA objects...?
type KeyType = {
    key_name: string,
    shared_key: string?, -- only required for HMAC
    public_key: string?, -- only required for RSA validation
    private_key: string?, -- only required for RSA signing
}
export type Key = typeof(setmetatable({} :: KeyType, enSNEP))

-- TODO: Signed Network Encapsulation Protocol

function enSNEP.NewRSA(key_name: string, public_key: string?, private_key: string?, hash_algo: string?): Key
    local self = {}
    self.key_name = key_name
    self.public_key = public_key
    self.private_key = private_key
    return setmetatable(self, enSNEP)
end

function enSNEP.NewHMAC(key_name: string, shared_key: string, hash_algo: string?): Key
    local self = {}
    self.key_name = key_name
    self.shared_key = shared_key
    return setmetatable(self, enSNEP)
end

function enSNEP.GetName(self: Key): string
    return self.key_name
end

function enSNEP._GetPublicKey(self: Key): string?
    return self.public_key
end

function enSNEP._GetPrivateKey(self: Key): string?
    return self.private_key
end

function enSNEP._GetSharedKey(self: Key): string?
    return self.shared_key
end

return enSNEP
