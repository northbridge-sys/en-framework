--!strict

local enPUMA = {
    ENCODING = {
        ASCII = "a",
        BASE64 = "6",
        BASE92 = "9",
        UNDEFINED = "*"
    },
    SCOPE = {
        DESCRIPTION = 0x1,
        HOVERTEXT = 0x2
    }
}

function enPUMA.WritePair(link: number, key: string, value: any?, encoding: string?, scope: number?): ()
    encoding = encoding or enPUMA.ENCODING.UNDEFINED
    scope = scope or bit32.bor(enPUMA.SCOPE.DESCRIPTION, enPUMA.SCOPE.HOVERTEXT)

    -- value encoding
    if value then
        if encoding == enPUMA.ENCODING.BASE64 then
            value = ll.StringToBase64(tostring(value))
        elseif encoding == enPUMA.ENCODING.BASE92 then
            error(`BASE92 not implemented`) -- TODO
        end
    end

    -- Invalid character check
    local value_ok = true
    for _, char in {"~", "|"} do -- ~ is the list separator, and | is disallowed in names and descriptions
        -- TODO: I know there is a better way to do this, but lua's matches scare me
        if #string.split(key, char) > 1 then
            error(`Invalid {char} in key {key}`)
        end
        if value then
            if #string.split(value, char) > 1 then
                value_ok = false
            end
        end
    end

    if not value_ok then
        -- we were passed a value as ASCII or undefined, but it can't be represented in printable PUMA-safe ASCII, so convert to base64 instead
        encoding = enPUMA.ENCODING.BASE64
        value = ll.StringToBase64(tostring(value))
    end

    -- read PUMA from prim
    local puma = enPUMA.GetTable(ll.GetLinkKey(link))
    if value then
        puma[key] = encoding :: string .. value :: string
    else
        puma[key] = nil
    end
    enPUMA._WriteTable(link, scope :: number, puma)
end

function enPUMA._WriteTable(link: number, scope: number, puma: {}): ()
    -- prioritize description, then hovertext, then name
    local puma_list = {}
    for key, value in puma do
        table.append(puma_list, key, value)
    end
    local text = table.concat(puma_list, "~")

    if bit32.btest(scope :: number, enPUMA.SCOPE.DESCRIPTION) then
        ll.SetLinkPrimitiveParamsFast(link, {PRIM_DESC, "!~" .. string.sub(text, 1, 125)})
        text = string.sub(text, 126)
        if #text == 0 then return end
    end
    if bit32.btest(scope :: number, enPUMA.SCOPE.HOVERTEXT) then
        ll.SetLinkPrimitiveParamsFast(link, {PRIM_TEXT, "!~" .. string.sub(text, 1, 252), vector(0, 0, 0), 0.0})
        text = string.sub(text, 253)
        if #text == 0 then return end
    end
    error(`enPUMA array length exceeded`)
end

function enPUMA.DecodeValue(value: string): string
    local encoding = string.sub(value, 1, 1)
    value = string.sub(value, 2)
    if encoding == enPUMA.ENCODING.BASE64 then
        return ll.Base64ToString(value)
    elseif encoding == enPUMA.ENCODING.BASE92 then
        error(`BASE92 not implemented`) -- TODO
    end
    return value
end

function enPUMA.GetTable(prim_uuid: uuid, decode: boolean?): {}
    local details = ll.GetObjectDetails(prim_uuid, {OBJECT_DESC, OBJECT_TEXT})
    if #details == 0 or not details then
        error(`Could not find prim {prim_uuid}`)
    end
    local text = ""
    for i = 1, 2 do
        if string.sub(details[i], 1, 2) == "!~" and #details[i] > 2 then
            text ..= string.sub(details[i], 3)
            if string.sub(text, -1, -1) == "`" then
                -- end of array - don't read any additional fields
                i = 3
                text = string.sub(text, 1, -2)
            end
        end
    end
    if text == "" then return {} end
    local puma_list = string.split(text, "~")
    local puma = {}
    for i = 1, #puma_list, 2 do
        puma[puma_list[i]] = puma_list[i + 1]
        if decode then puma[puma_list[i]] = enPUMA.DecodeValue(puma[puma_list[i]]) end
    end
    return puma
end

function enPUMA.ReadPair(prim_uuid: uuid, key: string): string?
    local puma = enPUMA.GetTable(prim_uuid, true)
    return puma[key]
end

return enPUMA