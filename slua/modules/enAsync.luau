--!strict

--[[
Adapted from https://suzanna-linn.github.io/slua/scripts-async-await

example events:

LLEvents:on("dataserver", enAsync.Awaiting)

enCLEP.ListenChat("Domain", true, function (clep: enCLEPTypes.Message): ()
    -- filter out stuff here
    if enAsync.Awaiting(clep.payload.id, clep) then return end
end)
]]

local enMultival = require("@en-framework/enMultival")

local enTimers: typeof(require("@en-framework/enTimers"))

local enAsync = {
    _awaiting = {} :: {[uuid|string]: {
        co: thread,
        entimer_promise: uuid|string?
    }}
}

-- Internal function.
function enAsync._Timeout(
    entimer_promise: uuid|string,
    ...: any
): ()
    -- something timed out, return the await as nil (resumes coroutine)
    local args = {...}
    if typeof(args[1]) == "thread" then
        coroutine.resume(args[1], nil)
    end
end

--[[
Creates a coroutine and calls the function (with parameters) passed into this function.
If there is an error, report the error.
@param func Any function
@param ... Any arguments to pass to func
]]
function enAsync.Async(func: (...any) -> (), ...: any): ()
    assert(enTimers, "Run enAsync.Init() first")
    local success, message = coroutine.resume(coroutine.create(func), ...)
    -- check if the coroutine returned an error
    if success then return end
    local func_name, line = debug.info(3, "nl")
    error(`Error in coroutine called in {if func_name ~= "" then "function " .. func_name else "main script"} at line {line}: {message}`, 3)
end

--[[
Call this function with the result of any operation that was awaited, such as enCLEP.Send -> clep_message.
@param potentially_awaited_promise Any UUID/string; if it is being awaited, the related coroutine is resumed
@param ... Any data; if the UUID/string is being awaited, the data is returned back out of enAsync.Await
@result true if a coroutine was resumed (and ran); false if none existed for this promise
]]
function enAsync.Awaiting(
    potentially_awaited_promise: uuid|string,
    ...: any
): boolean
    if not enAsync._awaiting[potentially_awaited_promise] then
        return false
    end
    if enAsync._awaiting[potentially_awaited_promise].entimer_promise then
        enTimers.Off(nil, enAsync._awaiting[potentially_awaited_promise].entimer_promise)
    end
    local co = enAsync._awaiting[potentially_awaited_promise].co
    enAsync._awaiting[potentially_awaited_promise] = nil
    --print(`enAsync: Awaited return: {potentially_awaited_promise}`)
    coroutine.resume(co, ...)
    return true
end

--[[
Catches the uuid returned from a function that returns a promise (such as enCLEP.Send) and awaits it (yields the coroutine).
Must be run from inside a coroutine (namely, in an enAsync.Async call).
It would be a good idea to wrap this in a pcall.
@param promise_to_await Any UUID/string
@param timeout_seconds Optional: Number of seconds until the coroutine resumes, returning nil
@return Any data ultimately passed as an argument to enAsync.Awaiting
]]
function enAsync.Await(
    promise_to_await: uuid|string,
    timeout_seconds: number?
): ...any?
    local co = coroutine.running()
    assert(co, `No running coroutine`)
    enAsync._awaiting[promise_to_await] = {
        co = co
    }
    if timeout_seconds then
        enAsync._awaiting[promise_to_await].entimer_promise = enTimers.Once(timeout_seconds, enAsync._Timeout, nil, promise_to_await)
    end
    return coroutine.yield()
end

--[[
Equivalent to enAsync.Await, but performs a type check of the returned value (or multival).
Must be run from inside a coroutine (namely, in an enAsync.Async call).
It would be a good idea to wrap this in a pcall.
@param promise_to_await Any UUID/string
@param timeout_seconds Optional: Number of seconds until the coroutine resumes, returning nil
@param ... Types to expect to be passed into enAsync.Awaiting (use nil to ignore a type)
@return Any data ultimately passed as an argument to enAsync.Awaiting
]]
function enAsync.AwaitTyped(
    promise_to_await: uuid|string,
    timeout_seconds: number?,
    ...: string?
): ...any?
    local result = {enAsync.Await(promise_to_await, timeout_seconds, ...)}
    if enMultival.IsOnlyNil(...) then
        return ...
    end
    local type_args = {...}
    if #type_args ~= #result then
        error(`Await returned {#result} vars, expected {#type_args}`)
    end
    for i = 1, #type_args do
        if type_args[i] and typeof(result[i]) ~= type_args[i] then
            error(`Await returned {typeof(result[i])} for arg #{i}, expected {type_args[i]}: {result[i]}`)
        end
    end
    return ...
end

--[[
Lazy loader.
@param _enTimers enTimers
]]
function enAsync.Init(
    _enTimers: typeof(enTimers)
): ()
    enTimers = _enTimers
end

return enAsync
