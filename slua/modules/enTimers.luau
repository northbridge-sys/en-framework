--!strict

--[[
enTimers is a wrapper module around LLTimers with some quality-of-life improvements, mainly the ability to cache a variant argument to simplify multiple timeouts. Also known as, Oops, I Accidentally Made LLTimers Again.

This is slightly less precision and does not follow the LLTimers cadence rule. It is prone to drift. It is intended to be used for low-priority callbacks that need to be called on the order of seconds. However, unlike the LSL enTimer module, the SLua enTimers module is compatible with LLTimers, so if you need higher precision, you can always just use LLTimers directly.

Uses about 3400 bytes of memory (plus the data you store as args).
]]

local enTimers = {
    _reset_pending = false,
    _running = {} :: {[uuid|string]:{
        interval: number?,
        clock: number,
        func: (promise: uuid|string, ...any) -> (),
        args: {any}
    }}
}

function enTimers._ResetTimer(): ()
    --[[
    this function is called when editing any timer
    if we are in the middle of a previous _ResetTimer() call,
    we don't want to bother resetting the timer,
    since once the callback function returns,
    the original _ResetTimer() will re-scan the _running table anyway
    ]]
    if enTimers._reset_pending then return end

    -- we always want to reset the LLTimers timer, so just off it early
    LLTimers:off(enTimers._ResetTimer)
    
    -- go through each running timer and check if it's triggered
    -- at the same time, find the soonest timer that hasn't triggered yet
    local triggered_promises = {} :: {uuid|string}
    for promise, running in pairs(enTimers._running) do
        -- we have a slack of 2 frames here for practiality's sake
        if running.clock <= os.clock() + 0.0445 then
            -- this timer is triggered
            -- save its promise for running the function later
            table.insert(triggered_promises, promise)
            if running.interval then
                -- it's an every (repeating) timer, so write new clock value
                running.clock = os.clock() + running.interval
            end
        end
    end

    -- trigger all the timer callback functions
    enTimers._reset_pending = true
    for _, promise in ipairs(triggered_promises) do
        -- we need to do it like this because we need to erase the running promise first if it's one-shot
        -- however, we still need the func and args, so we break them off first
        local promise_data = enTimers._running[promise]
        if not enTimers._running[promise].interval then
            enTimers._running[promise] = nil
        end
        promise_data.func(promise, unpack(promise_data.args))
    end
    enTimers._reset_pending = false

    -- set the LLTimers timer, if needed
    local lowest_clock = nil :: number?
    for promise, running in pairs(enTimers._running) do
        if not lowest_clock or running.clock < lowest_clock then
            -- this timer is, so far, the closest un-triggered timer
            lowest_clock = running.clock
        end
    end
    if lowest_clock then
        -- we have running timer(s)
        local set_clock = os.clock()
        if lowest_clock <= set_clock + 0.0223 then
            -- we can't set a timer for less than one frame,
            -- so start over and just trigger it
            enTimers._ResetTimer()
            return
        end
        -- we have a time in the future, so set the timer
        LLTimers:once(lowest_clock - set_clock, enTimers._ResetTimer)
    end
end

--[[
Starts a one-shot timer.
Slightly less accurate than LLTimers:once().
@param seconds Interval in seconds
@param callback_function Function to call when timer triggers
@param promise Optional: any UUID, used as promise
@param ... Optional: any data, will be passed as an argument to callback_function
@return promise
]]
function enTimers.Once(
    seconds: number,
    callback_function: (promise: uuid|string, ...any) -> (),
    promise: uuid|string?,
    ...: any
): uuid|string
    -- generate a promise, if we didn't get one
    if typeof(promise) ~= "uuid" and typeof(promise) ~= "string" then
        promise = ll.GenerateKey()
    end
    -- write the timer to memory
    enTimers._running[promise] = {
        interval = nil,
        clock = os.clock() + seconds,
        func = callback_function,
        args = {...}
    }
    enTimers._ResetTimer()
    return promise
end

--[[
Starts a repeating timer.
Slightly less accurate than LLTimers:every().
@param seconds Interval in seconds
@param callback_function Function to call when timer triggers
@param promise Optional: any UUID, used as promise
@param ... Optional: any data, will be passed as an argument to callback_function
@return promise
]]
function enTimers.Every(
    seconds: number,
    callback_function: (promise: uuid|string, ...any) -> (),
    promise: uuid|string?,
    ...: any
): uuid
    -- generate a promise, if we didn't get one
    if typeof(promise) ~= "uuid" and typeof(promise) ~= "string" then
        promise = ll.GenerateKey()
    end
    -- write the timer to memory
    enTimers._running[promise] = {
        interval = seconds,
        clock = os.clock() + seconds,
        func = callback_function,
        args = {...}
    }
    enTimers._ResetTimer()
    return promise
end

--[[
Cancels a timer. At least one parameter must be defined.
@param callback_function Optional: callback_function from Once() or Every()
@param promise Optional: promise
@return true if found, false if not
]]
function enTimers.Off(
    callback_function: (promise: uuid|string, ...any) -> ()?,
    promise: uuid|string?
): boolean
    if promise and enTimers._running[promise] then
        -- found via promise
        LLTimers:off(enTimers._running[promise].func)
        enTimers._running[promise] = nil
        enTimers._ResetTimer()
        return true
    end
    -- can LLTimers find it?
    if not callback_function or not LLTimers:off(callback_function) then
        -- nope. we can't either then, so don't waste time trying
        return false
    end
    -- LLTimers found it, so we should be able to find it
    -- unfortunately this is slightly less efficient
    -- but if you're relying on functions anyway,
    -- you might just be able to use LLTimers raw
    for promise, running in pairs(enTimers._running) do
        if running.func == callback_function then
            -- found via function match
            -- we already off'd the LLTimers
            enTimers._running[promise] = nil
            enTimers._ResetTimer()
            return true
        end
    end
    -- couldn't find it for some reason (possibly double cancellation?)
    return false
end

return enTimers
