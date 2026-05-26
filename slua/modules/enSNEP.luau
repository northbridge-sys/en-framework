--!strict

local enSNEP = {
    _keys = {}
}
enSNEP.__index = enSNEP

-- SNEPKey type definition

-- Defines the enSNEPKey object.
-- This is where RPC signing keys for RSA/HMAC are stored.
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
type SignatureType = {
    sign_algo: string,
    hash_algo: string,
    key_name: string,
    signature: string
}
export type Signature = typeof(setmetatable({} :: SignatureType, enSNEP))

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

--[[
Notes on signature validation:
This implementation returns a verification when the signature is valid as checked against a known key and is within stale_seconds old.
This guarantees the author of the message, and prevents some replay attacks, but can still be defeated.
Prevent replay attacks completely by doing ONE of the following:
    - Only accept messages that have a unique id - essentially prevents replay attacks, but also prohibits id reuse, uses memory or datastorage, and requires pruning.
    - Check that metadata.source.prim matches payload.source.prim - eliminates source spoofing, but can't be used with relayed traffic.
]]

function enSNEP.Verify(payload: string, snep: Signature, payload_utime: number?, stale_seconds: number?): {key_name: string, sign_algo: "RSA" | "HMAC", hash_algo: string}?
    local seconds_to_check = stale_seconds or 1
    if seconds_to_check < 1 then seconds_to_check = 1 end
    local seconds_remaining = seconds_to_check
    local utime = os.time() :: number

    assert(enSNEP._keys[snep.key_name], `Unknown signature key_name: {snep.key_name}`)
    if snep.sign_algo == "RSA" then
        assert(enSNEP._keys[snep.key_name]:_GetPublicKey(), `Failed to get public key for {snep.key_name}`)
        while seconds_remaining > 0 do
            if ll.VerifyRSA(enSNEP._keys[snep.key_name]:_GetPublicKey() :: string, tostring(utime - (seconds_to_check - seconds_remaining)) .. payload, snep.signature, snep.hash_algo) then
                -- signature verified succesfully and is, at most, seconds_to_check old
                assert(not payload_utime or payload_utime == utime - (seconds_to_check - seconds_remaining), `Payload utime {payload_utime} does not match signature utime {utime - (seconds_to_check - seconds_remaining)}`)
                return {key_name = snep.key_name, sign_algo = snep.sign_algo, hash_algo = snep.hash_algo}
            end
            seconds_remaining -= 1
        end
        -- either the signature was invalid, our public key is wrong, or the signature is older than seconds_to_check
        error(`Failed to verify RSA signature for {snep.key_name}`)
    elseif snep.sign_algo == "HMAC" then
        assert(enSNEP._keys[snep.key_name]:_GetSharedKey(), `Failed to get shared key for {snep.key_name}`)
        while seconds_remaining > 0 do
            if ll.HMAC(enSNEP._keys[snep.key_name]:_GetSharedKey() :: string, tostring(utime - (seconds_to_check - seconds_remaining)) .. payload, snep.hash_algo) then
                -- signature verified succesfully and is, at most, seconds_to_check old
                assert(not payload_utime or utime - math.abs((seconds_to_check - seconds_remaining) - payload_utime) < 1.5, `Payload utime {payload_utime} does not match signature utime {utime - (seconds_to_check - seconds_remaining)}`)
                return {key_name = snep.key_name, sign_algo = snep.sign_algo, hash_algo = snep.hash_algo}
            end
            seconds_remaining -= 1
        end
        -- either the signature was invalid, our public key is wrong, or the signature is older than seconds_to_check
        error(`Failed to verify HMAC signature for {snep.key_name}`)
    else
        error(`Unknown signature sign_algo: {snep.sign_algo}`)
    end
end

function enSNEP.Enroll(key: Key): ()
    enSNEP._keys[key:_GetName()] = key
end

function enSNEP._NewSignature(sign_algo: string, hash_algo: string, key: Key, payload: string): Signature
    local self = {}
    self.sign_algo = sign_algo
    self.hash_algo = hash_algo
    self.key_name = key.key_name
    local utime = os.time()
    if self.sign_algo == "RSA" then
        self.signature = ll.SignRSA(key:_GetPrivateKey() :: string, tostring(utime) .. payload, hash_algo)
    else
        self.signature = ll.HMAC(key:_GetSharedKey() :: string, tostring(utime) .. payload, hash_algo)
    end
    return setmetatable(self, enSNEP)
end

function enSNEP._GetName(self: Key): string
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
