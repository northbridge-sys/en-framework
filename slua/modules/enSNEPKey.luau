--!strict


-- Defines the enSNEPKey object.
-- This is where RPC signing keys for RSA/HMAC are stored.
-- TODO: Split this into HMAC and RSA objects...?
local enSNEPKey = {}
enSNEPKey.__index = enSNEPKey
export type enSNEPKeyData = {
    key_name: string,
    shared_key: string?, -- only required for HMAC
    public_key: string?, -- only required for RSA validation
    private_key: string? -- only required for RSA signing
}
export type enSNEPKey = typeof(setmetatable({} :: enSNEPKeyData, enSNEPKey))

-- TODO: Signed Network Encapsulation Protocol

function enSNEPKey.newRSA(key_name: string, public_key: string?, private_key: string?, hash_algo: string?): enSNEPKey
    local self = {}
    self.key_name = key_name
    self.public_key = public_key
    self.private_key = private_key
    return setmetatable(self, enSNEPKey)
end

function enSNEPKey.newHMAC(key_name: string, shared_key: string, hash_algo: string?): enSNEPKey
    local self = {}
    self.key_name = key_name
    self.shared_key = shared_key
    return setmetatable(self, enSNEPKey)
end

function enSNEPKey.getName(self: enSNEPKey): string
    return self.key_name
end

function enSNEPKey._getPublicKey(self: enSNEPKey): string?
    return self.public_key
end

function enSNEPKey._getPrivateKey(self: enSNEPKey): string?
    return self.private_key
end

function enSNEPKey._getSharedKey(self: enSNEPKey): string?
    return self.shared_key
end

return enSNEPKey
