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

-- SNEPKey type definition

-- Defines the enSNEPKey object.
-- This is where RPC signing keys for RSA/HMAC are stored.
-- TODO: Split this into HMAC and RSA objects...?
type SignatureType = {
    sign_algo: string,
    hash_algo: string,
    key_name: string,
    utime: number,
    signature: string
}
export type Signature = typeof(setmetatable({} :: SignatureType, enSNEP))

-- TODO: Signed Network Encapsulation Protocol

function enSNEP.NewRSA(key_name: string, public_key: string?, private_key: string?): Key
    local self = {}
    self.key_name = key_name
    self.public_key = public_key
    self.private_key = private_key
    return setmetatable(self, enSNEP)
end

function enSNEP.NewHMAC(key_name: string, shared_key: string): Key
    local self = {}
    self.key_name = key_name
    self.shared_key = shared_key
    return setmetatable(self, enSNEP)
end

function enSNEP._NewSignature(sign_algo: string, hash_algo: string, key: Key, payload: string): Signature
    local self = {}
    self.sign_algo = sign_algo
    self.hash_algo = hash_algo
    self.key_name = key.key_name
    self.utime = os.time()
    if self.sign_algo == "RSA" then
        self.signature = ll.SignRSA(key:_GetPrivateKey() :: string, tostring(self.utime) .. payload, "sha512")
    else
        self.signature = ll.HMAC(key:_GetSharedKey() :: string, tostring(self.utime) .. payload, "sha512")
    end
    return setmetatable(self, enSNEP)
end

function enSNEP.Sign(payload: string, key: Key): Signature
    -- add SNEP signature
    if key:_GetPrivateKey() then
        return enSNEP._NewSignature(
            "RSA",
            "sha512",
            key,
            payload
        )
    elseif key:_GetSharedKey() then
        return enSNEP._NewSignature(
            "HMAC",
            "sha512",
            key,
            payload
        )
    else
        error(`invalid SNEP key`)
    end
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
