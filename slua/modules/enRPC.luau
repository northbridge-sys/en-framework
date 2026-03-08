--!strict

local enConsole = require("enConsole")

-- TODO: if listening to own prim UUID on UUID change (see Prim(?)), change to new channel

local enRPC = {
    _LEP = {
        listens = {}
    },
    _CLEP = {
        listens = {}
    },
    _keys = {}
}

function enRPC.CLEPChannel(domain: string): number
    local channel = ll.Hash(domain)
    if channel == 0 or channel == 0x7FFFFFFF then
        channel = channel - 1
    end
    return channel
end

-- initialize DIALOG_CHANNEL constant
enRPC.DIALOG_CHANNEL = enRPC.CLEPChannel(tostring(ll.GetInventoryKey(ll.GetScriptName())))

function enRPC.LEPListen(domain: string?, handler_function: (payload: {}) -> ()): ()

    enConsole.Trace(`enRPC.LEPListen("{domain}", ...)`)

    local active_listens = 0
    for _ in pairs(enRPC._LEP.listens) do
        active_listens = active_listens + 1
    end

    -- if we haven't already subscribed to link_message events, do so now
    if active_listens == 0 then
        LLEvents:on("link_message", enRPC._link_message)
        enConsole.Debug("LEP hooked")
    end

    if not domain then
        -- setting up the fallback handler function
        enRPC._LEP.fallback = handler_function
        return
    end

    -- setting up a domain handler function
    enRPC._LEP.listens[domain] = handler_function

    return
end

function enRPC.CLEPListen(domain: string, owner_only: boolean, handler_function: (payload: {}) -> ()): ()

    -- TODO: what about passing nil to handler_function? that causes this to fail since it creates a Listen but points nowhere

    if not enRPC._CLEP.listens[domain] then
        local active_listens = 0
        for _ in pairs(enRPC._CLEP.listens) do
            active_listens = active_listens + 1
        end

        -- we will be adding a new listen, can we afford it?
        assert(active_listens < 64, "too many listens")

        -- if we haven't already subscribed to listen events, do so now
        if active_listens == 0 then
            LLEvents:on("listen", enRPC._listen)
            enConsole.Debug("CLEP hooked")
        end

        -- create the Listen
        enRPC._CLEP.listens[domain] = {
            handle = ll.Listen(enRPC.CLEPChannel(domain), "", NULL_KEY, "")
        }
    end

    enRPC._CLEP.listens[domain].owner_only = owner_only
    enRPC._CLEP.listens[domain].handler = handler_function

    enConsole.Trace(`enRPC.CLEPListen("{domain}" ({enRPC.CLEPChannel(domain)}), {owner_only}, ...) ➔ {enRPC._CLEP.listens[domain].handle}`)

    return
end

function enRPC._link_message(linknum: number, num: number, message: string, key: string): ()

    --nbsToolkit.Log.Trace(`nbsToolkit.LEP._link_message({linknum}, {num}, "{message}", "{key}") ➔ ...`)

    local success, rpc = xpcall(enRPC.Unmarshal(message, {link = linknum}), enConsole.Error) -- returns nil if message should be dropped
    if not success or not rpc or not rpc.payload or not rpc.payload.domain then return end

    rpc.payload.source.link = linknum -- set source link

    --nbsToolkit.Log.Trace(`nbsToolkit.LEP._link_message({linknum}, {num}, "{message}", "{key}") ➔ {rpc.payload}`)

    enRPC._LEP.listens[rpc.payload.domain].handler(rpc.payload)
end

function enRPC._listen(channel: number, name: string, key: uuid, message: string): ()

    enConsole.Trace(`enRPC._listen({channel}, "{name}", "{key}", "{message}") ➔ ...`)

    --local success, rpc = xpcall(enRPC.Unmarshal(message, {prim = key}), nbsToolkit.Log.Error)
    --if not success or not payload then return end -- payload is nil if the message should be dropped
    local rpc = enRPC.Unmarshal(message, {prim = key}) -- returns nil if message should be dropped
    if not rpc or not rpc.payload or not rpc.payload.domain then return end

    if enRPC._CLEP.listens[rpc.payload.domain].owner_only and ll.GetOwnerKey(key) ~= ll.GetOwner() then return end -- listener is owner-only, drop this message

    --nbsToolkit.Log.Trace(`nbsToolkit.CLEP._listen({channel}, "{name}", "{key}", "{message}") ➔ {rpc.payload}`)

    enRPC._CLEP.listens[rpc.payload.domain].handler(rpc)
end

function enRPC.LEPListenRemove(domain: string?): ()

    if domain then assert(enRPC._LEP.listens[domain], `LEP domain not found: {domain}`) end

    enConsole.Trace(`enRPC.LEPListenRemove("{domain}")`)

    if not domain then
        enRPC._LEP.fallback = nil
        return
    end

    enRPC._LEP.listens[domain] = nil

    local active_listens = 0
    for _ in pairs(enRPC._LEP.listens) do
        active_listens = active_listens + 1
    end

    -- we are no longer listening to any domains, unsubscribe from link_message event to avoid double subscribing if LEP.Listen is called again from no listens
    if active_listens == 0 then
        LLEvents:off("link_message", enRPC._link_message)
        enConsole.Debug("LEP unhooked")
    end

    return
end

function enRPC.CLEPListenRemove(domain: string): ()

    assert(enRPC._CLEP.listens[domain], `CLEP domain not found: {domain}`)

    if enRPC._CLEP.listens[domain].handle and enRPC._CLEP.listens[domain].handle ~= 0 then ll.ListenRemove(enRPC._CLEP.listens[domain].handle) end

    enConsole.Trace(`enRPC.CLEPListenRemove("{domain}")`)

    enRPC._CLEP.listens[domain] = nil

    local active_listens = 0
    for _ in pairs(enRPC._CLEP.listens) do
        active_listens = active_listens + 1
    end

    -- we are no longer listening to any domains, unsubscribe from listen event to avoid double subscribing if CLEP.Listen is called again from no listens
    if active_listens == 0 then
        LLEvents:off("listen", enRPC._listen)
        enConsole.Debug("CLEP unhooked")
    end

    return
end

function enRPC.LEPReset(): ()
    local active_listens = 0
    for _ in pairs(enRPC._LEP.listens) do
        active_listens = active_listens + 1
    end

    if active_listens == 0 then return end

    LLEvents:off("link_message", enRPC._link_message)
    enConsole.Debug("LEP unhooked")

    for domain, data in pairs(enRPC._LEP.listens) do
        enRPC._LEP.listens[domain] = nil
    end
end

function enRPC.CLEPReset(): ()
    local active_listens = 0
    for _ in pairs(enRPC._CLEP.listens) do
        active_listens = active_listens + 1
    end

    if active_listens == 0 then return end

    LLEvents:off("listen", enRPC._listen)
    enConsole.Debug("CLEP unhooked")

    for domain, data in pairs(enRPC._CLEP.listens) do
        if data.handle and data.handle ~= 0 then ll.ListenRemove(data.handle) end
        enRPC._CLEP.listens[domain] = nil
    end
end

function enRPC.EnrollSNEPKey(key: enSNEPKey): ()
    enRPC._keys[key:getName()] = key
    enConsole.Trace(`Enrolled SNEP key {key:getName()}`)
end

function enRPC.Send(
    key: enSNEPKey?,
    target: {
        region: string?,
        prim: uuid?,
        link: number?,
        script: string?
    },
    domain: string,
    id: uuid?,
    method: {string},
    params: any?,
    result: any?
): ()

    --nbsToolkit.Log.Trace(`nbsToolkit.enRPC.Send(..., {target}, {domain}, {id}, {method}, {params}, {result}) ➔ ...`)

    local payload = {
        timestamp = os.time(),
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
        result = result
    }

    -- set output in "transit" encapsulation; first, encode payload to have a static signable message
    local output = {
        clep = lljson.encode(payload)
    }

    if key then
        -- add SNEP signature
        if key:_getPrivateKey() then
            output.snep = {
                sign_algo = "RSA",
                key_name = key.key_name,
                hash_algo = "sha256",
                signature = ll.SignRSA(key:_getPrivateKey(), output.clep, "sha256")
            }
        elseif key:_getSharedKey() then
            output.snep = {
                sign_algo = "HMAC",
                key_name = key.key_name,
                hash_algo = "sha512",
                signature = ll.HMAC(key:_getSharedKey(), output.clep, "sha512")
            }
        else
            error(`invalid sign_algo: {key.sign_algo}`)
        end
    end

    -- send it
    local channel = enRPC.CLEPChannel(payload.domain);
    if not payload.target.prim then
        -- broadcasting to all prims in the region
        ll.RegionSay(channel, lljson.encode(output))
        --nbsToolkit.Log.Trace(`... ➔ ll.RegionSay({channel}, ...)`)
        return
    end
    local link = tonumber(ll.GetObjectDetails(payload.target.prim, {OBJECT_LINK_NUMBER})[1]) -- attempt to get the linknum of the prim within its linkset
    if link then
        -- prim exists in the region
        if touuid(ll.GetLinkKey(link)) == payload.target.prim then
            -- the UUID of the linknum within our OWN linkset matches the one passed in, it is part of our linkset
            -- use MessageLinked
            ll.MessageLinked(link, 0, lljson.encode(output), NULL_KEY)
            --nbsToolkit.Log.Trace(`... ➔ ll.MessageLinked({link}, ...)`)
            return
        end
        -- prim is in some other linkset in the region, try RegionSayTo
        ll.RegionSayTo(payload.target.prim, channel, lljson.encode(output))
        --nbsToolkit.Log.Trace(`... ➔ ll.RegionSayTo({payload.target.prim}, {channel}, ...)`)
        return
    end
    -- prim does not exist in this region, try to shout over the region border
    ll.Shout(channel, lljson.encode(output))
    --nbsToolkit.Log.Trace(`... ➔ ll.Shout({channel}, ...)`)
    return
end

function enRPC.Unmarshal(message: string, source: {prim: uuid?, link: number?}): {
    metadata: {
        source: {
            link: number?,
            prim: uuid
        },
        key_name: string?,
        hash_algo: string?
    },
    payload: {
        timestamp: number,
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
}?

    local data = lljson.decode(message)

    local data_payload = lljson.decode(data.clep)

    local id_u = touuid(data_payload.id)

    if     typeof(data_payload.timestamp) ~= "number"
        or typeof(data_payload.source.region) ~= "string"
        or typeof(data_payload.source.prim) ~= "string"
        or typeof(data_payload.source.script) ~= "string"
        or typeof(data_payload.target) ~= "table"
        or typeof(data_payload.domain) ~= "string"
        or typeof(data_payload.id) ~= "string"
        or not id_u
     then
        --nbsToolkit.Log.Trace(`CLEP syntax error: {data.clep}`)
        return
    end

    local payload = {
        timestamp = data_payload.timestamp,
        source = data_payload.source,
        target = data_payload.target,
        domain = data_payload.domain,
        id = id_u,
        method = data_payload.method,
        params = data_payload.params,
        result = data_payload.result
    }

    payload.source.prim = touuid(payload.source.prim) -- convert source.prim back to uuid for type safety (nil passes through)
    payload.target.prim = touuid(payload.target.prim) -- convert target.prim back to uuid for type safety (nil passes through)

    -- TODO: add a way to bypass these filters
    if payload.target.region and payload.target.region ~= ll.GetRegionName() then
        --nbsToolkit.Log.Trace("mismatched target.region")
        return
    end
    if payload.target.prim and payload.target.prim ~= ll.GetKey() then
        --nbsToolkit.Log.Trace("mismatched target.prim")
        return
    end
    if payload.target.script and payload.target.script ~= ll.GetScriptName() then
        --nbsToolkit.Log.Trace("mismatched target.script")
        return
    end

    local metadata = {source = source}

    if source.link then
        -- we received this message via link_message, so grab the prim's UUID too
        metadata.source.prim = ll.GetLinkKey(source.link)
    end

    --[[
    Notes on signature validation:
    This implementation returns metadata.key_name when the signature is valid as checked against a known key.
    This is the ONLY check it performs. This guarantees the author of the message, but not its originality or source.
    Prevent replay attacks by doing the following:
        - Check that metadata.timestamp is within 1 second of os.time() - prevents unsophisticated replay attacks, but requires one of the two following mitigations to eliminate all replay attacks:
        - Only accept messages that have a unique id - essentially prevents replay attacks, but also prohibits id reuse, uses memory or datastorage, and requires pruning.
        - Check that metadata.source.prim matches payload.source.prim - eliminates source spoofing, but can't be used with relayed traffic.
    ]]

    if data.snep then
        -- we have a signature to validate
        if not enRPC._keys[data.snep.key_name] then
            enConsole.Trace(`unknown signature key_name: {data.snep.key_name}`)
        elseif data.snep.sign_algo == "RSA" then
            if not enRPC._keys[data.snep.key_name]:_getPublicKey() then
                enConsole.Trace(`failed to get public key for {data.snep.key_name}`)
            elseif not ll.VerifyRSA(enRPC._keys[data.snep.key_name]:_getPublicKey(), data.clep, data.snep.signature, data.snep.hash_algo) then
                enConsole.Trace(`failed to verify RSA signature for {data.snep.key_name}`)
            else
                -- valid signature
                enConsole.Trace(`verified RSA signature for {data.snep.key_name}`)
                metadata.key_name = data.snep.key_name
                metadata.hash_algo = data.snep.hash_algo
            end
        elseif data.snep.sign_algo == "HMAC" then
            if not enRPC._keys[data.snep.key_name]:_getSharedKey() then
                enConsole.Trace(`failed to get shared key for {data.snep.key_name}`)
            elseif not ll.HMAC(enRPC._keys[data.snep.key_name]:_getSharedKey(), data.clep, data.snep.hash_algo) then
                enConsole.Trace(`failed to verify HMAC signature for {data.snep.key_name}`)
            else
                -- valid signature
                enConsole.Trace(`verified HMAC signature for {data.snep.key_name}`)
                metadata.key_name = data.snep.key_name
                metadata.hash_algo = data.snep.hash_algo
            end
        else
            enConsole.Trace(`unknown signature.sign_algo: {data.snep.sign_algo}`)
        end
    end

    if typeof(payload.domain) ~= "string" then
        enConsole.Trace(`CLEP payload.domain is {typeof(payload.domain)}: {payload.domain}`)
        return
    end
    
    return {metadata = metadata, payload = payload}
end

return enRPC
