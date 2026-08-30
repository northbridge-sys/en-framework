--!strict

local enSNEPTypes = require("@en-framework/types/enSNEPTypes")

local enSNEP = {
    _keys = {}
}
enSNEP.__index = enSNEP

--[[
Notes on signature validation:
This implementation returns a verification when the signature is valid as checked against a known key and is within stale_seconds old.
This guarantees the author of the message, and prevents some replay attacks, but can still be defeated.
Prevent replay attacks completely by doing ONE of the following:
    - Only accept messages that have a unique id - essentially prevents replay attacks, but also prohibits id reuse, uses memory or datastorage, and requires pruning.
    - Check that metadata.source.prim matches payload.source.prim - eliminates source spoofing, but can't be used with relayed traffic.
]]

function enSNEP.Verify(payload: string, snep: enSNEPTypes.Signature, payload_utime: number?, stale_seconds: number?): {key_name: string, sign_algo: string, hash_algo: string}?
    local seconds_to_check = stale_seconds or 1
    if seconds_to_check < 1 then seconds_to_check = 1 end
    local seconds_remaining = seconds_to_check
    local utime = os.time() :: number

    assert(enSNEP._keys[snep.key_name], `Unknown signature key_name: {snep.key_name}`)
    if snep.sign_algo == "RSA" then
        assert(enSNEP._keys[snep.key_name].public_key, `Failed to get public key for {snep.key_name}`)
        while seconds_remaining > 0 do
            if ll.VerifyRSA(enSNEP._keys[snep.key_name].public_key, tostring(utime - (seconds_to_check - seconds_remaining)) .. payload, snep.signature, snep.hash_algo) then
                -- signature verified succesfully and is, at most, seconds_to_check old
                assert(not payload_utime or payload_utime == utime - (seconds_to_check - seconds_remaining), `Payload utime {payload_utime} does not match signature utime {utime - (seconds_to_check - seconds_remaining)}`)
                return {key_name = snep.key_name, sign_algo = "RSA", hash_algo = snep.hash_algo}
            end
            seconds_remaining -= 1
        end
        -- either the signature was invalid, our public key is wrong, or the signature is older than seconds_to_check
        error(`Failed to verify RSA signature for {snep.key_name}`)
    elseif snep.sign_algo == "HMAC" then
        assert(enSNEP._keys[snep.key_name].shared_key, `Failed to get shared key for {snep.key_name}`)
        while seconds_remaining > 0 do
            if ll.HMAC(enSNEP._keys[snep.key_name].shared_key, tostring(utime - (seconds_to_check - seconds_remaining)) .. payload, snep.hash_algo) then
                -- signature verified succesfully and is, at most, seconds_to_check old
                return {key_name = snep.key_name, sign_algo = "HMAC", hash_algo = snep.hash_algo}
            end
            seconds_remaining -= 1
        end
        -- either the signature was invalid, our public key is wrong, or the signature is older than seconds_to_check
        error(`Failed to verify HMAC signature for {snep.key_name}`)
    else
        error(`Unknown signature sign_algo: {snep.sign_algo}`)
    end
end

function enSNEP.Enroll(key: enSNEPTypes.Key): ()
    enSNEP._keys[key.key_name] = key
end


function enSNEP.Sign(payload: string, key: enSNEPTypes.Key, hash_algo: string?): enSNEPTypes.Signature
    -- add enSNEPTypes signature
    if key.private_key then
        return enSNEPTypes._NewSignature(
            "RSA",
            hash_algo or "sha256",
            key,
            payload
        )
    elseif key.shared_key then
        return enSNEPTypes._NewSignature(
            "HMAC",
            hash_algo or "sha256",
            key,
            payload
        )
    else
        error(`Invalid enSNEPTypes key`)
    end
end

return enSNEP
