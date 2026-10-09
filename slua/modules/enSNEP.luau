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

Refer to https://gsi.sh/rec/snep for more information on SNEP signatures.
]]

--[[
Generates a SNEP signature for a provided payload using a provided key.
@param payload_raw Any string
@param key Any enSNEP HMAC or RSA signing key
@param expiry_seconds Optional: number of seconds until the signature expires (default 60)
@param hash_algo Optional: hash algorithm to use (default sha256)
@return SNEP signature string, typically passed as a CLEP header
]]
function enSNEP.GenerateSignature(
    payload_raw: string,
    key: enSNEPTypes.HMACKey|enSNEPTypes.RSAKeyPair,
    expiry_seconds: number?,
    hash_algo: "sha1"|"sha224"|"sha256"|"sha384"|"sha512"?
): string
    local nonce = ll.GenerateKey()
    local expire_time = os.time() + (expiry_seconds or 60)
    local output = {
        h = hash_algo or "sha256",
        k = key.key_name,
        n = nonce,
        e = expire_time
    }
    if key.sym then
        output.t = "HMAC"
        output.s = ll.HMAC(key.secret :: string, tostring(nonce) .. tostring(expire_time) .. payload_raw, hash_algo or "sha256")
    else
        output.t = "RSA"
        output.s = ll.SignRSA(key.private_key :: string, tostring(nonce) .. tostring(expire_time) .. payload_raw, hash_algo or "sha256")
    end
    return lljson.encode(output)
end

--[[
Checks to see if a SNEP signature passed for a specified payload is valid using any matching enrolled key.
@param payload_raw String that was signed
@param snep_token SNEP signature token from header
@return {key_name = name of key used, sign_algo = "HMAC" or "RSA", hash_algo = hash algorithm}, or nil if the signature could not be verified
]]
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

    assert(enSNEP._keys[snep_token_data.k], `Unknown signature key_name: {snep_token_data.k}`)
    if snep_token_data.t == "RSA" then
        assert(enSNEP._keys[snep_token_data.k].public_key, `Failed to get public key for {snep_token_data.k}`)
        if ll.VerifyRSA(enSNEP._keys[snep_token_data.k].public_key, tostring(snep_token_data.e) .. payload_raw, snep_token_data.s, snep_token_data.h) then
            -- signature verified succesfully
            return {key_name = snep_token_data.k, sign_algo = "RSA", hash_algo = snep_token_data.h}
        end
        -- either the signature was invalid, our public key is wrong, or the signature is older than seconds_to_check
        error(`Failed to verify RSA signature for {snep_token_data.k}`)
    elseif snep_token_data.t == "HMAC" then
        assert(enSNEP._keys[snep_token_data.k].secret, `Failed to get secret for {snep_token_data.k}`)
        if ll.HMAC(enSNEP._keys[snep_token_data.k].secret, tostring(snep_token_data.e) .. payload_raw, snep_token_data.h) == snep_token_data.s then
            -- signature verified succesfully
            return {key_name = snep_token_data.k, sign_algo = "HMAC", hash_algo = snep_token_data.h}
        end
        -- either the signature was invalid, our public key is wrong, or the signature is older than seconds_to_check
        error(`Failed to verify HMAC signature for {snep_token_data.k}`)
    else
        error(`Unknown signature sign_algo: {snep_token_data.s}`)
    end
end

function enSNEP.Enroll(key: enSNEPTypes.HMACKey|enSNEPTypes.RSAKeyPair|enSNEPTypes.RSAPublicKey): ()
    enSNEP._keys[key.key_name] = key
end

return enSNEP
