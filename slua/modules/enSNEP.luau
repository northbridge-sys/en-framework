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

function enSNEP.GenerateTokenHMAC(
    payload_raw: string,
    hmac_key: enSNEPTypes.HMACKey,
    expiry_seconds: number?,
    hash_algo: "md5"|"sha1"|"sha224"|"sha256"|"sha384"|"sha512"?
): string
    local expire_time = os.time() + (expiry_seconds or 60)
    return lljson.encode({
        sa = "HMAC", -- sign algo
        ha = hash_algo or "sha256",
        kn = hmac_key.key_name,
        e = expire_time,
        s = ll.HMAC(hmac_key.secret :: string, tostring(expire_time) .. payload_raw, hash_algo or "sha256")
    })
end

function enSNEP.GenerateTokenRSA(
    payload_raw: string,
    rsa_key_pair: enSNEPTypes.RSAKeyPair,
    expiry_seconds: number?,
    hash_algo: "sha1"|"sha224"|"sha256"|"sha384"|"sha512"?
): string
    local expire_time = os.time() + (expiry_seconds or 60)
    return lljson.encode({
        sa = "RSA", -- sign algo
        ha = hash_algo or "sha256",
        kn = rsa_key_pair.key_name,
        e = expire_time,
        s = ll.SignRSA(rsa_key_pair.private_key :: string, tostring(expire_time) .. payload_raw, hash_algo or "sha256")
    })
end

function enSNEP.Verify(
    payload_raw: string,
    snep_token: string
): {
    key_name: string,
    sign_algo: string,
    hash_algo: string
}?
    local utime = os.time() :: number

    local success, snep_token_data = pcall(lljson.decode(snep_token))
    if not success or not snep_token_data then
        error(`Failed to decode token`)
    end
    if utime > snep_token_data.e then
        error(`Token expired`)
    end

    assert(enSNEP._keys[snep_token_data.kn], `Unknown signature key_name: {snep_token_data.kn}`)
    if snep_token_data.sa == "RSA" then
        assert(enSNEP._keys[snep_token_data.kn].public_key, `Failed to get public key for {snep_token_data.kn}`)
        if ll.VerifyRSA(enSNEP._keys[snep_token_data.kn].public_key, tostring(snep_token_data.e) .. payload_raw, snep_token_data.s, snep_token_data.ha) then
            -- signature verified succesfully
            return {key_name = snep_token_data.kn, sign_algo = "RSA", hash_algo = snep_token_data.ha}
        end
        -- either the signature was invalid, our public key is wrong, or the signature is older than seconds_to_check
        error(`Failed to verify RSA signature for {snep_token_data.kn}`)
    elseif snep_token_data.sa == "HMAC" then
        assert(enSNEP._keys[snep_token_data.kn].secret, `Failed to get secret for {snep_token_data.kn}`)
        if ll.HMAC(enSNEP._keys[snep_token_data.kn].secret, tostring(snep_token_data.e) .. payload_raw, snep_token_data.ha) == snep_token_data.s then
            -- signature verified succesfully
            return {key_name = snep_token_data.kn, sign_algo = "HMAC", hash_algo = snep_token_data.ha}
        end
        -- either the signature was invalid, our public key is wrong, or the signature is older than seconds_to_check
        error(`Failed to verify HMAC signature for {snep_token_data.kn}`)
    else
        error(`Unknown signature sign_algo: {snep_token_data.sa}`)
    end
end

function enSNEP.Enroll(key: enSNEPTypes.HMACKey|enSNEPTypes.RSAKeyPair|enSNEPTypes.RSAPublicKey): ()
    enSNEP._keys[key.key_name] = key
end

return enSNEP
