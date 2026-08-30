--!strict

-- TODO: if listening to own prim UUID on UUID change (see Prim(?)), change to new channel
--[[
TODO: enCLEP relays
check source.region and see if region has a known routing
if so, write the routing data via relay encapsulation protocol that adds a hash of each routing step to encapsulation layer for loopback detection and packet return
]]

local enCLEPTypes = require("@en-framework/types/enCLEPTypes")
local enSNEPTypes = require("@en-framework/types/enSNEPTypes")

local enCHUF = require("@en-framework/enCHUF")

local enConsole: typeof(require("@en-framework/enConsole"))
local enDump: typeof(require("@en-framework/enDump")) -- only required if verbose logging is enabled and inbound event logging is desired
local enListen: typeof(require("@en-framework/enListen"))?
local enSNEP: typeof(require("@en-framework/enSNEP"))

local enCLEP = {
    _link = {
        handlers = {}
    },
    _chat = {
        handlers = {}
    },
    _verbose = false,
    _initstring = "Call enCLEP.Init(...) first",
    _init = false
}
enCLEP.__index = enCLEP

--[[
Initializes enCLEP. Required on script start.
@param _enConsole enConsole
@param _enListen Optional: enListen (only required for chat operations)
@param verbose_logging Optional: Whether to enable verbose trace logs for deep debugging
@param _enDump: Optional: enDump (only required for enListen event verbose logging)
@param _enSNEP: Optional: enSNEP (only required for SNEP signing/validation)
]]
function enCLEP.Init(
    _enConsole: typeof(enConsole),
    _enListen: typeof(enListen)?,
    verbose_logging: boolean?,
    _enDump: typeof(enDump)?,
    _enSNEP: typeof(enSNEP)?): ()
    enConsole = _enConsole
    enListen = _enListen
    if _enDump then enDump = _enDump end
    if _enSNEP then enSNEP = _enSNEP end
    enCLEP._verbose = verbose_logging or false
    enCLEP._init = true
    enConsole.Trace(`enCLEP initialized`)
end

function enCLEP._link_message(linknum: number, num: number, message: string, key: uuid|string): any?

    if enCLEP._verbose then enConsole.Trace(`enCLEP._link_message({linknum}, {num}, "{message}", "{key}") ➔ ...`) end

    -- for link messages, they are passed in raw, so we have to decode them ourselves first
    local success_json, data = pcall(lljson.sldecode, message)
    if not success_json then return 0x10 end
    if typeof(data) ~= "table" then return 0x11 end

    local success, clep = pcall(enCLEP._Unmarshal, data, {prim = ll.GetLinkKey(linknum), link = linknum})
    if not success then
        if enCLEP._verbose then enConsole.Trace(`Dropped CLEP message from link {linknum}: {clep}`) end
        return 0x12
    end

    if not clep then return 0x13 end -- silently dropped message

    if not enCLEP._link.handlers[clep.payload.domain] then
        return 0x14
    end -- not listening to this domain

    return enCLEP._link.handlers[clep.payload.domain](clep)
end

function enCLEP._listen(domain: string | number, name: string, key: uuid, data: any): any?
    
    if enCLEP._verbose and enDump then enConsole.Trace(`enCLEP._listen("{domain}", "{name}", "{key}", {enDump.Table(data)}) ➔ ...`) end

    -- for listens, enListen does the json decode and passes a raw data value, so we can skip the decode here
    local success, clep = pcall(enCLEP._Unmarshal, data, {prim = key})
    if not success then
        if enCLEP._verbose then enConsole.Trace(`Dropped CLEP message from {key}: {clep}`) end
        return 0x10
    end

    if not clep then return 0x11 end -- silently dropped message

    if not enCLEP._chat.handlers[clep.payload.domain] then
        return 0x12
    end -- not listening to this domain

    return enCLEP._chat.handlers[clep.payload.domain](clep)
end

--[[
Starts listening to a CLEP domain via link_message.
@param domain CLEP domain
@param handler_function Function that will be called with inbound CLEP link messages that pass all built-in filters
]]
function enCLEP.ListenLink(domain: string, handler_function: (clep: enCLEPTypes.Message) -> ()): ()
    assert(enCLEP._init, enCLEP._initstring)
    enConsole.Trace(`enCLEP.ListenLink("{domain}", ...)`)

    if enCLEP._link.handlers[domain] then
        -- update existing handler
        enCLEP._link.handlers[domain] = handler_function
        return
    end

    if next(enCLEP._link.handlers) == nil then
        -- first link listen, subscribe to the link_message event
        LLEvents:on("link_message", enCLEP._link_message)
    end

    enCLEP._link.handlers[domain] = handler_function
end

--[[
Starts listening to a CLEP domain via chat listen.
@param domain CLEP domain
@param owner_only Filters out messages from objects not owned by the same agent (also blocks messages from objects not in the region)
@param handler_function Function that will be called with inbound CLEP chat messages that pass all built-in filters
]]
function enCLEP.ListenChat(domain: string, owner_only: boolean, handler_function: (clep: enCLEPTypes.Message) -> (), source_uuid: uuid?): ()
    assert(enCLEP._init, enCLEP._initstring)
    assert(enListen, "enListen not initialized")
    enListen.Open(enCLEP._listen, owner_only, domain, nil, source_uuid, nil, "table")
    enCLEP._chat.handlers[domain] = handler_function

    enConsole.Trace(`enCLEP.ListenChat("{domain}" ({enCHUF.Channel(domain)}), {owner_only}, ...)`)
end

--[[
Stops listening to a CLEP domain via link_message.
@param domain CLEP domain
]]
function enCLEP.ListenRemoveLink(domain: string): ()
    assert(enCLEP._init, enCLEP._initstring)
    assert(enCLEP._link.handlers[domain], `Domain not found: {domain}`)

    enConsole.Trace(`enCLEP.ListenRemoveLink("{domain}")`)

    enCLEP._link.handlers[domain] = nil

    -- we are no longer listening to any domains, unsubscribe from link_message event
    if next(enCLEP._link.handlers) == nil then
        LLEvents:off("link_message", enCLEP._link_message)
    end
end

--[[
Stops listening to a CLEP domain via chat listen.
@param domain CLEP domain
]]
function enCLEP.ListenRemoveChat(domain: string): ()
    assert(enCLEP._init, enCLEP._initstring)
    assert(enListen, "enListen not initialized")
    assert(enCLEP._chat.handlers[domain], `Domain not found: {domain}`)

    enConsole.Trace(`enCLEP.ListenRemoveChat("{domain}")`)

    enListen.Close(domain)

    enCLEP._chat.handlers[domain] = nil
end

--[[
Stops listening to ALL CLEP domains via link_message.
]]
function enCLEP.ListenRemoveLinkAll(): ()
    if next(enCLEP._link.handlers) then return end

    LLEvents:off("link_message", enCLEP._link_message)

    for domain in pairs(enCLEP._link.handlers) do
        enCLEP._link.handlers[domain] = nil
    end
end

--[[
Stops listening to ALL CLEP domains via chat listen.
]]
function enCLEP.ListenRemoveChatAll(): ()
    assert(enListen, "enListen not initialized")
    if next(enCLEP._chat.handlers) then return end

    for domain in pairs(enCLEP._chat.handlers) do
        enListen.Close(domain)
        enCLEP._chat.handlers[domain] = nil
    end
end

--[[
Sends a message via CLEP, either via chat or link message, depending on target.
@param key Optional: enSNEP Key to sign the message with
@param target A table of "region" (targets only scripts in named region); "prim" (targets only scripts in identified prim); "root" (targets only scripts in linkset with identified prim as root); "link" (targets only scripts in a prim with this link number); "script" (targets only scripts with this inventory name); and "force_chat" (forces the message to be sent via chat, even if it is to another prim in the same linkset) options, all optional and combinable
@param domain CLEP domain
@param method CLEP method (array of strings, used for message classification)
@param params Optional: Any data (required for responses, which must return the request's clep.payload.params)
@param id Optional: Force a message UUID (required for responses, which must return the request's clep.payload.id)
@param result Optional: Any data (required for responses, to signal a response)
@return Message UUID used for outbound message (can be awaited, though there is no guarantee of a response)
]]
function enCLEP.Send(
    key: enSNEPTypes.Key?,
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

    -- set output in "transit" encapsulation; first, slencode payload to have a static signable message
    local output = {
        payload = lljson.slencode(payload)
    }

    if key then
        output.snep = enSNEP.Sign(output.payload, key)
    else
        -- if we're not using a SNEP signature, add the optional CLEP-level utime value
        output.utime = os.time()
    end

    local channel = enCHUF.Channel(payload.domain);

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
        enCLEP._link_message(ll.GetLinkNumber(), 0, lljson.slencode(output), NULL_KEY) -- pass it back in as if it were received as a link_message
        if enCLEP._verbose then enConsole.Trace(`{func_trace} ➔ enCLEP._link_message(...) (loopback)`) end
        return payload.id
    end

    -- direct link target
    if target.link then
        -- we are using a link number or LINK_* constant (LINK_SET, LINK_ALL_OTHERS, LINK_ALL_CHILDREN, or LINK_THIS)
        if target.force_chat then
            -- use RegionSayTo
            ll.RegionSayTo(ll.GetLinkKey(target.link), channel, lljson.slencode(output))
            if enCLEP._verbose then enConsole.Trace(`{func_trace} ➔ ll.RegionSayTo({ll.GetLinkKey(target.link)}, {channel}, ...) (forced from link {target.link})`) end
            return payload.id
        else
            -- use MessageLinked
            ll.MessageLinked(target.link, 0, lljson.slencode(output), uuid(NULL_KEY) :: uuid)
            if enCLEP._verbose then enConsole.Trace(`{func_trace} ➔ ll.MessageLinked({target.link}, ...)`) end
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
                ll.MessageLinked(link, 0, lljson.slencode(output), uuid(NULL_KEY) :: uuid)
                if enCLEP._verbose then enConsole.Trace(`{func_trace} ➔ ll.MessageLinked({link}, ...)`) end
                return payload.id
            end
            -- prim is in some other linkset in the region
            -- use RegionSayTo
            ll.RegionSayTo(target.prim, channel, lljson.slencode(output))
            if enCLEP._verbose then enConsole.Trace(`{func_trace} ➔ ll.RegionSayTo({target.prim}, {channel}, ...)`) end
            return payload.id
        end
        -- prim does not exist in this region
        -- use Shout (can cross region border up to 100m)
        ll.Shout(channel, lljson.slencode(output))
        if enCLEP._verbose then enConsole.Trace(`{func_trace} ➔ ll.Shout({channel}, ...)`) end
        return payload.id
    end

    -- no target set
    -- broadcast to all prims in the region
    -- use RegionSay
    ll.RegionSay(channel, lljson.slencode(output))
    if enCLEP._verbose then enConsole.Trace(`{func_trace} ➔ ll.RegionSay({channel}, ...)`) end
    return payload.id
end

--[[
Responds to a message via CLEP, either via chat or link message, depending on the original source.
@param key Optional: enSNEP Key to sign the message with
@param clep enCLEP Message to respond to
@param result Any data
@return Message UUID used for outbound message (can generally be ignored)
]]
function enCLEP.Respond(
    key: enSNEPTypes.Key?,
    clep: enCLEPTypes.Message?,
    result: any
): uuid
    if not clep then return nil end
    return enCLEP.Send(
        key,
        clep.payload.source :: any,
        clep.payload.domain,
        clep.payload.method,
        clep.payload.params,
        clep.payload.id,
        result
    )
end

function enCLEP._MissingElement(path: string, required: string, got: string): ()
    error(`Missing CLEP element {path} as {required} (got {got})`)
end

function enCLEP._Unmarshal(data: any, source: {prim: uuid, link: number?}): enCLEPTypes.Message?

    local data_payload
    if data.payload then -- payload is encapsulated - we use slencode specifically for the payload
        data_payload = lljson.sldecode(data.payload)
    else -- payload is not encapsulated
        data_payload = data
    end

    if typeof(data_payload.utime) ~= "number" then enCLEP._MissingElement("utime", "number", typeof(data_payload.utime)) end
    if typeof(data_payload.source.region) ~= "string" then enCLEP._MissingElement("source.region", "string", typeof(data_payload.source.region)) end
    if typeof(data_payload.source.prim) ~= "string" then enCLEP._MissingElement("source.prim", "string", typeof(data_payload.source.prim)) end
    if typeof(data_payload.source.script) ~= "string" then enCLEP._MissingElement("source.script", "string", typeof(data_payload.source.script)) end
    if typeof(data_payload.target) ~= "table" then enCLEP._MissingElement("target", "table", typeof(data_payload.target)) end
    if typeof(data_payload.domain) ~= "string" then enCLEP._MissingElement("domain", "string", typeof(data_payload.domain)) end
    local id_u = touuid(data_payload.id)
    if typeof(data_payload.id) ~= "string" or not id_u then enCLEP._MissingElement("id", "string", typeof(data_payload.id)) end

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
        local verification = enSNEP.Verify(data.payload, data.snep, payload.utime, 10) -- TODO: allow modification of stale_seconds
        if verification then -- signature verified successfully
            metadata.key_name = verification.key_name
            metadata.hash_algo = verification.hash_algo
            metadata.sign_algo = verification.sign_algo
        end
    end

    return enCLEPTypes.NewMessage({metadata = metadata, payload = payload} :: any)
end

return enCLEP
