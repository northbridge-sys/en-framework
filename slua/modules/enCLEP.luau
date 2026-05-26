--!strict

-- TODO: if listening to own prim UUID on UUID change (see Prim(?)), change to new channel
--[[
TODO: enCLEP relays
check source.region and see if region has a known routing
if so, write the routing data via relay encapsulation protocol that adds a hash of each routing step to encapsulation layer for loopback detection and packet return
]]

local enCLEP = {
    _link = {
        listens = {}
    },
    _chat = {
        listens = {}
    },
    _init = false,
    _initstring = "Call enCLEP.Init(...) first"
}
enCLEP.__index = enCLEP

-- Message type definition

type MessageType = {
    metadata: {
        source: {
            link: number?,
            prim: uuid,
            script: string? -- if an enhanced messaging function ever appears that can guarantee a source script name, it may be used
        },
        key_name: string?,
        hash_algo: string?,
        sign_algo: "RSA" | "HMAC"?
    },
    payload: {
        utime: number,
        source: {
            region: string,
            prim: uuid,
            script: string
        },
        target: {
            link: number?,
            region: string?,
            prim: uuid?,
            script: string?
        },
        domain: string,
        id: uuid,
        method: {string},
        params: any?,
        result: any?
    }
}
export type Message = typeof(setmetatable({} :: MessageType, enCLEP))

function enCLEP.NewMessage(
    metadata: {
        source: {
            link: number?,
            prim: uuid,
            script: string?
        },
        key_name: string?,
        hash_algo: string?,
        sign_algo: "RSA" | "HMAC"?
    },
    payload: {
        utime: number,
        source: {
            region: string,
            prim: uuid,
            script: string
        },
        target: {
            link: number?,
            region: string?,
            prim: uuid?,
            script: string?
        },
        domain: string,
        id: uuid,
        method: {string},
        params: any?,
        result: any?
    }
): Message
    local self = {metadata = metadata, payload = payload}
    return setmetatable(self, enCLEP)
end

-- Dependency management

local enConsole: typeof(require("@en-framework/enConsole"))
local enSNEP: typeof(require("@en-framework/enSNEP"))

----
function enCLEP.Init(dependency_enConsole: typeof(enConsole)?, dependency_enSNEP: typeof(enSNEP)?): ()
    if dependency_enConsole then enConsole = dependency_enConsole end
    if dependency_enSNEP then enSNEP = dependency_enSNEP end
    enCLEP._init = true
    if enConsole then enConsole.Trace(`enCLEP initialized`) end
end

function enCLEP._link_message(linknum: number, num: number, message: string, key: string): ()

    --enConsole.Trace(`enCLEP.LEP._link_message({linknum}, {num}, "{message}", "{key}") ➔ ...`)

    local success, clep = pcall(enCLEP.Unmarshal, message, {prim = ll.GetLinkKey(linknum), link = linknum})
    if not success then
        if enConsole then enConsole.Trace(`Dropped CLEP message from link {linknum}: {clep}\n{message}`) end
        return
    end

    if not clep then return end -- silently dropped message

    if not enCLEP._link.listens[clep.payload.domain] then return end -- not listening to this domain

    enCLEP._link.listens[clep.payload.domain].handler(clep)
end

function enCLEP._listen(channel: number, name: string, key: uuid, message: string): ()

    --enConsole.Trace(`enCLEP._listen({channel}, "{name}", "{key}", "{message}") ➔ ...`)

    local success, clep = pcall(enCLEP.Unmarshal, message, {prim = key})
    if not success then
        if enConsole then enConsole.Trace(`Dropped CLEP message from {key}: {clep}\n{message}`) end
        return
    end

    if not clep then return end -- silently dropped message

    if not enCLEP._chat.listens[clep.payload.domain] then return end -- not listening to this domain

    if enCLEP._chat.listens[clep.payload.domain].owner_only and ll.GetOwnerKey(key) ~= ll.GetOwner() then
        if enConsole then enConsole.Trace(`Dropped non-owner CLEP message from {key}`) end
        return
    end

    enCLEP._chat.listens[clep.payload.domain].handler(clep)
end

function enCLEP.CLEPChannel(domain: string): number
    return bit32.bor(ll.Hash(domain), 0x80000000)
end

function enCLEP.ListenLink(domain: string, handler_function: (clep: Message) -> ()): ()
    if not enCLEP._init then error(enCLEP._initstring) end
    if enConsole then enConsole.Trace(`enCLEP.ListenLink("{domain}", ...)`) end

    if enCLEP._link.listens[domain] then
        -- update existing handler
        enCLEP._link.listens[domain].handler = handler_function
        return
    end

    local active_listens = 0
    for _ in pairs(enCLEP._link.listens) do
        active_listens = active_listens + 1
    end

    -- if we haven't already subscribed to link_message events, do so now
    if active_listens == 0 then
        LLEvents:on("link_message", enCLEP._link_message)
        if enConsole then enConsole.Debug("link_message hooked") end
    end

    -- setting up a domain handler function
    enCLEP._link.listens[domain] = {
        handler = handler_function
    }
end

function enCLEP.ListenChat(domain: string, owner_only: boolean, handler_function: (clep: Message) -> ()): ()
    if not enCLEP._init then error(enCLEP._initstring) end
    -- TODO: what about passing nil to handler_function? that causes this to fail since it creates a Listen but points nowhere

    if enCLEP._chat.listens[domain] then
        -- updating existing handler
        enCLEP._chat.listens[domain].handler = handler_function
        return
    end

    local active_listens = 0
    for _ in pairs(enCLEP._chat.listens) do
        active_listens = active_listens + 1
    end

    -- we will be adding a new listen, can we afford it?
    assert(active_listens < 64, "too many listens")

    -- if we haven't already subscribed to listen events, do so now
    if active_listens == 0 then
        LLEvents:on("listen", enCLEP._listen)
        if enConsole then enConsole.Debug("listen hooked") end
    end

    -- create the Listen, set up the domain handler function, and add options
    enCLEP._chat.listens[domain] = {
        handle = ll.Listen(enCLEP.CLEPChannel(domain), "", NULL_KEY, ""),
        handler = handler_function,
        owner_only = owner_only
    }

    if enConsole then enConsole.Trace(`enCLEP.ListenChat("{domain}" ({enCLEP.CLEPChannel(domain)}), {owner_only}, ...) ➔ {enCLEP._chat.listens[domain].handle}`) end

    return
end

function enCLEP.ListenRemoveLink(domain: string): ()
    if domain then assert(enCLEP._link.listens[domain], `LEP domain not found: {domain}`) end

    if enConsole then enConsole.Trace(`enCLEP.ListenRemoveLink("{domain}")`) end

    enCLEP._link.listens[domain] = nil

    local active_listens = 0
    for _ in pairs(enCLEP._link.listens) do
        active_listens = active_listens + 1
    end

    -- we are no longer listening to any domains, unsubscribe from link_message event to avoid double subscribing if LEP.Listen is called again from no listens
    if active_listens == 0 then
        LLEvents:off("link_message", enCLEP._link_message)
        if enConsole then enConsole.Debug("link_message unhooked") end
    end

    return
end

function enCLEP.ListenRemoveChat(domain: string): ()
    assert(enCLEP._chat.listens[domain], `CLEP domain not found: {domain}`)

    if enCLEP._chat.listens[domain].handle and enCLEP._chat.listens[domain].handle ~= 0 then ll.ListenRemove(enCLEP._chat.listens[domain].handle) end

    if enConsole then enConsole.Trace(`enCLEP.ListenRemoveChat("{domain}")`) end

    enCLEP._chat.listens[domain] = nil

    local active_listens = 0
    for _ in pairs(enCLEP._chat.listens) do
        active_listens = active_listens + 1
    end

    -- we are no longer listening to any domains, unsubscribe from listen event to avoid double subscribing if CLEP.Listen is called again from no listens
    if active_listens == 0 then
        LLEvents:off("listen", enCLEP._listen)
        if enConsole then enConsole.Debug("listen unhooked") end
    end

    return
end

function enCLEP.ListenRemoveLinkAll(): ()
    local active_listens = 0
    for _ in pairs(enCLEP._link.listens) do
        active_listens = active_listens + 1
    end

    if active_listens == 0 then return end

    LLEvents:off("link_message", enCLEP._link_message)
    if enConsole then enConsole.Debug("link_message unhooked") end

    for domain, data in pairs(enCLEP._link.listens) do
        enCLEP._link.listens[domain] = nil
    end
end

function enCLEP.ListenRemoveChatAll(): ()
    local active_listens = 0
    for _ in pairs(enCLEP._chat.listens) do
        active_listens = active_listens + 1
    end

    if active_listens == 0 then return end

    LLEvents:off("listen", enCLEP._listen)
    if enConsole then enConsole.Debug("listen unhooked") end

    for domain, data in pairs(enCLEP._chat.listens) do
        if data.handle and data.handle ~= 0 then ll.ListenRemove(data.handle) end
        enCLEP._chat.listens[domain] = nil
    end
end

function enCLEP.Send(
    key: enSNEP.Key?,
    target: {
        region: string?,
        prim: uuid?,
        root: uuid?,
        link: number?,
        script: string?,
        force_chat: boolean?
    },
    domain: string,
    method: {string},
    params: any?,
    id: uuid?,
    result: any?
): uuid
    if target.prim == NULL_KEY then
        target.prim = nil -- do not allow passing NULL_KEY as target_prim, because it will not be accepted by anyone
    end

    local func_trace = `enCLEP.Send(domain = "{domain}", method = \{ "{table.concat(method, `", "`)}" \}, id = {tostring(id)}, target = \{ region = "{target.region}", prim = {target.prim}, root = {target.root}, link = {target.link}, script = "{target.script}" \}, params: {typeof(params)}, result: {typeof(result)}...) ➔ `

    local payload = {
        source = {
            region = ll.GetRegionName(),
            prim = ll.GetKey(),
            script = ll.GetScriptName() -- TODO: relays will need to be able to set this themselves, maybe wrap into a separate SendRaw function?
        },
        target = target,
        domain = domain,
        id = id or ll.GenerateKey(),
        method = method,
        params = params,
        result = result,
        utime = os.time()
    }

    payload.target.force_chat = nil -- do not pass force_chat param

    -- set output in "transit" encapsulation; first, encode payload to have a static signable message
    local output = {
        payload = lljson.encode(payload)
    }

    if key then
        output.snep = enSNEP.Sign(output.payload, key)
    else
        -- if we're not using a SNEP signature, add the optional CLEP-level utime value
        output.utime = os.time()
    end

    local channel = enCLEP.CLEPChannel(payload.domain);

    --[[
    Possible target configurations:

    All listening scripts in this region:
    {}

    All listening scripts in a specific prim in this linkset by link number:
    {link = link_number}

    All listening scripts in a specific prim in any linkset (this opportunistically routes via MessageLinked):
    {prim = prim_uuid}

    To force RegionSayTo for other prims in this linkset (not this prim), add to any above configuration:
    {force_chat = true}

    To allow CLEP relays to route your message, add to any above configuration:
    {region = region_name}

    To target a specific script, add to any above configuration:
    {script = script_name}

    Loopback (calls handler function directly):
    {link = LINK_THIS, script = ll.GetScriptName()}
    ]]

    -- loopback
    if target.script and target.script == ll.GetScriptName() and (
        (target.link and target.link == LINK_THIS or target.link == ll.GetLinkNumber())
        or (target.prim and target.prim == ll.GetKey())
    ) then
        enCLEP._link_message(ll.GetLinkNumber(), 0, lljson.encode(output), NULL_KEY) -- pass it back in as if it were received as a link_message
        if enConsole then enConsole.Trace(`{func_trace} ➔ enCLEP._link_message(...) (loopback)`) end
        return payload.id
    end

    -- direct link target
    if target.link then
        -- we are using a link number or LINK_* constant (LINK_SET, LINK_ALL_OTHERS, LINK_ALL_CHILDREN, or LINK_THIS)
        if target.force_chat then
            -- use RegionSayTo
            ll.RegionSayTo(ll.GetLinkKey(target.link), channel, lljson.encode(output))
            if enConsole then enConsole.Trace(`{func_trace} ➔ ll.RegionSayTo({ll.GetLinkKey(target.link)}, {channel}, ...) (forced from link {target.link})`) end
            return payload.id
        else
            -- use MessageLinked
            ll.MessageLinked(target.link, 0, lljson.encode(output), NULL_KEY)
            if enConsole then enConsole.Trace(`{func_trace} ➔ ll.MessageLinked({target.link}, ...)`) end
            return payload.id
        end
    end

    -- direct prim target
    if target.prim then
        -- check if it exists in the region
        local link = tonumber(ll.GetObjectDetails(target.prim, {OBJECT_LINK_NUMBER})[1]) -- attempt to get the linknum of the prim within its linkset
        if link then
            -- prim exists in the region
            if ll.GetLinkKey(link) == target.prim and (not target.force_chat or link == ll.GetLinkNumber()) then
                -- the UUID of the linknum within our OWN linkset matches the targeted prim's UUID, so it is part of our linkset
                -- use MessageLinked instead of RegionSayTo, since it's faster and RST fails on same-prim messages
                -- if you want to not use link messages at all between prims, force chat for other prims in the same linkset (not same prim) using target.force_chat = true
                ll.MessageLinked(link, 0, lljson.encode(output), NULL_KEY)
                if enConsole then enConsole.Trace(`{func_trace} ➔ ll.MessageLinked({link}, ...)`) end
                return payload.id
            end
            -- prim is in some other linkset in the region
            -- use RegionSayTo
            ll.RegionSayTo(target.prim, channel, lljson.encode(output))
            if enConsole then enConsole.Trace(`{func_trace} ➔ ll.RegionSayTo({target.prim}, {channel}, ...)`) end
            return payload.id
        end
        -- prim does not exist in this region
        -- use Shout (can cross region border up to 100m)
        ll.Shout(channel, lljson.encode(output))
        if enConsole then enConsole.Trace(`{func_trace} ➔ ll.Shout({channel}, ...)`) end
        return payload.id
    end

    -- no target set
    -- broadcast to all prims in the region
    -- use RegionSay
    ll.RegionSay(channel, lljson.encode(output))
    if enConsole then enConsole.Trace(`{func_trace} ➔ ll.RegionSay({channel}, ...)`) end
    return payload.id
end

function enCLEP.Unmarshal(message: string, source: {prim: uuid, link: number?}): Message?

    local success, data = pcall(lljson.decode, message)
    if not success then error(`Not valid CLEP message`) end -- not a valid CLEP message

    local data_payload = lljson.decode(data.payload)

    local id_u = touuid(data_payload.id)

    if     typeof(data_payload.utime) ~= "number"
        or typeof(data_payload.source.region) ~= "string"
        or typeof(data_payload.source.prim) ~= "string"
        or typeof(data_payload.source.script) ~= "string"
        or typeof(data_payload.target) ~= "table"
        or typeof(data_payload.domain) ~= "string"
        or typeof(data_payload.id) ~= "string"
        or not id_u
    then
        error(`Missing required CLEP element`)
    end

    local payload = {
        utime = data_payload.utime,
        source = data_payload.source,
        target = data_payload.target,
        domain = data_payload.domain,
        id = id_u,
        method = data_payload.method,
        params = data_payload.params,
        result = data_payload.result
    }

    if payload.source.prim then payload.source.prim = touuid(payload.source.prim) end -- convert source.prim back to uuid for type safety
    if payload.target.prim then payload.target.prim = touuid(payload.target.prim) end -- convert target.prim back to uuid for type safety

    if payload.source.script == ll.GetScriptName() and source.link == ll.GetLinkNumber() then return end -- heard own message

    -- TODO: add a way to bypass these filters
    if payload.target.region and payload.target.region ~= ll.GetRegionName() then
        error(`Mismatched CLEP target.region`)
    end
    if payload.target.prim and payload.target.prim ~= ll.GetKey() then
        error(`Mismatched CLEP target.prim`)
    end
    if payload.target.script and payload.target.script ~= ll.GetScriptName() then
        error(`Mismatched CLEP target.script`)
    end

    local metadata = {source = source}

    if data.snep and enSNEP then
        -- we have a signature to validate
        local verification = enSNEP.Verify(data.payload, data.snep, payload.utime, 1) -- TODO: allow modification of stale_seconds
        if verification then -- signature verified successfully
            metadata.key_name = verification.key_name
            metadata.hash_algo = verification.hash_algo
            metadata.sign_algo = verification.sign_algo
        end
    end

    return enCLEP.NewMessage(metadata, payload)
end

return enCLEP
