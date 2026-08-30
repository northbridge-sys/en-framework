--[[
enListen is a general-purpose ll.Listen wrapper. It adds:
    - Domains (strings that are hashed into a negative chat channel lower than about -1,000,000,000, which avoids conflicts and ensures maximum 1024-byte limit for messages)
    - Proper error reporting for exceeding limit of 65 listens (the ll.Listen call shouts on DEBUG_CHANNEL even if you catch it with pcall())
    - Built-in same-owner filtering
    - Built-in lljson.sldecode processing and typechecking
]]

--!strict

local enCHUF = require("@en-framework/enCHUF")

local enListen = {
    _open = {}
}

--- Opens a chat listen via ll.Listen, passing messages to a callback function if they pass optional source and type tests.
-- @param callback Callback function.
-- @param owner_only If enabled, messages received from source not owned by the same owner are silently discarded.
-- @param domain_or_channel Either a string or channel number.
-- @param name Source name filter for ll.Listen.
-- @param source_uuid Source UUID filter for ll.Listen.
-- @param message Message filter for ll.Listen.
-- @param type Either nil (pass message as-is), "" (pass result if lljson.sldecode() can decode the message, regardless of type), or a type string ("table", "string", etc. - pass result only if lljson.sldecode() returns that type)
-- @return number Handle number of ll.Listen (you don't need to save this).
function enListen.Open(
    callback: (
        domain: string | number,
        name: string,
        source_uuid: uuid,
        message: any
    ) -> (),
    owner_only: boolean,
    domain_or_channel: string | number,
    name: string?,
    source_uuid: uuid?,
    message: string?,
    type: string? -- either nil (passes raw message), an expected type after converting from json using lljson.sldecode() (passes only expected type), or "" (passes any type)
): ()
    enListen.Close(domain_or_channel)
    local count = 0
    for _ in pairs(enListen._open) do count += 1 end
    assert(count < 65, "Too many listens") -- maximum 65 listens per script

    local channel = enCHUF.Channel(domain_or_channel)

    if enListen._open[channel] then
        -- we have a channel conflict
        if enListen._open[channel].domain ~= domain_or_channel then
            -- we are not overwriting the existing listen, but the channel hash conflicts with another domain we're already listening to
            -- this should basically never happen, but if it does, it is usually a transient problem caused by a very improbable 31-bit hash collision with UUID-derived domains
            -- typically re-rezzing fixes this, but if not, you'll just have to change your domains. consider buying a lottery ticket also
            error("enListen channel conflict (try re-rezzing)")
        end
    end
    
    if next(enListen._open) == nil then
        -- first chat listen, subscribe to the listen event
        LLEvents:on("listen", enListen._listen)
    end

    local handle = ll.Listen(channel, name or "", source_uuid or uuid(NULL_KEY) :: uuid, message or "")
    enListen._open[channel] = {domain = domain_or_channel, handle = handle, owner_only = owner_only, type = type, callback = callback}
end

--- Closes a chat listen opened with enListen.Open by domain or channel number instead of handle.
-- @param domain_or_channel Domain string or channel number to find.
-- @return boolean True if a listen was closed; false if none was found.
function enListen.Close(domain_or_channel: string | number): boolean
    local channel = enCHUF.Channel(domain_or_channel)
    if not enListen._open[channel] then return false end
    ll.ListenRemove(enListen._open[channel].handle)
    enListen._open[channel] = nil

    if next(enListen._open) == nil then
        -- no more open listens, unsubscribe from the listen event
        LLEvents:off("listen", enListen._listen)
    end

    return true
end

--- Closes all chat listens opened with enListen.Open.
function enListen.CloseAll(): ()
    for channel, handle in pairs(enListen._open) do
        ll.ListenRemove(handle)
    end
    enListen._open = {}
    -- always unsubscribe
    LLEvents:off("listen", enListen._listen)
end

-- Internal ll.Listen callback.
function enListen._listen(channel: number, name: string, source_uuid: uuid, message: string): any?
    --print(`{ll.GetKey()} got: {message}`)
    local listen = enListen._open[channel]
    if not listen then return 0x1 end
    if listen.owner_only and ll.GetOwnerKey(source_uuid) ~= ll.GetOwner() then return 0x2 end
    if listen.type == nil then
        return listen.callback(channel, name, source_uuid, message)
    end

    local success, data = pcall(lljson.sldecode, message)
    if not success then return 0x3 end
    if typeof(data) ~= listen.type and listen.type ~= "" then return 0x4 end

    return listen.callback(channel, name, source_uuid, data)
end

return enListen