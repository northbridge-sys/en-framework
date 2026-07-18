--!strict

local enCHUF = {}

--- Hashes a string into a number that can be safely used as a script-to-script chat channel using the CHUF: https://gsi.sh/rec/chuf
-- @param domain Domain string.
-- @return number Channel number.
function enCHUF.Channel(domain_or_channel: string | number): number
    if typeof(domain_or_channel) == "number" then return domain_or_channel end -- pass numbers back as channels
    -- ORing with 0x80000000 guarantees the number is negative, which can't be sent via typical viewers
    -- ORing with 0x40000000 guarantees the number is lower than -1073741807, which is basically fair game for conflicts
    -- the resultant channel space is 30 bits, which is probably more than enough
    local channel = bit32.bor(ll.Hash(domain_or_channel), 0xC0000000)
    if channel >= 2^31 then channel -= 2^32 end -- avoid overflowing - bit32 numbers are returned as unsigned, but channels can only be signed 32-bit
    return channel
end

return enCHUF