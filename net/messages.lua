local messages = {}

local channels = {
    {name = "reliable", flag = "reliable"},
    {name = "inputUpdates", flag = "unreliable"},
    {name = "stateHashes", flag = "unreliable"},
}
for i, channel in ipairs(channels) do
    channel.id = i - 1
    channels[channel.name] = channel
end
messages.channels = channels

local function serializeMessage(message, ...)
    local args = select(1, ...)
    if type(args) == "table" then
        local packArgs = {}
        for _, key in ipairs(message.keys) do
            table.insert(packArgs, args[key])
        end
        return ld.pack("string", message.format, message.id, unpack(packArgs))
    else
        assert(select("#", ...) == #message.keys)
        return ld.pack("string", message.format, message.id, ...)
    end
end

local function deserializeMessage(message, str)
    local vals = {ld.unpack(message.format, str)}
    assert(vals[1] == message.id)
    local ret = {
        class = message,
        id = message.id,
    }
    -- last return value is not an unpacked value
    for i = 2, #vals - 1 do
        ret[message.keys[i-1]] = vals[i]
    end
    return ret
end

local function registerMessage(name, format, keys, channel)
    format = format or ""
    keys = keys or {}

    for _, key in pairs(keys) do
        assert(key ~= "id" and key ~= "class")
    end

    local messageClass = {
        id = #messages + 1,
        name = name,
        format = "<B" .. format, -- B for message id
        keys = keys,
        channel = channel,

        serialize = serializeMessage,
        deserialize = deserializeMessage,
    }
    messages[messageClass.id] = messageClass
    messages[name] = messageClass
end

function messages.deserialize(str)
    local id = str:byte(1)
    local messageClass = assert(messages[id])
    return messageClass:deserialize(str)
end

registerMessage("clientHello", "z", {"version"})
registerMessage("hostHello", "BBs2", {"success", "reason", "gameInfo"})
-- the first byte in "inputState" is from "frame", the second from "frame" - 1, etc.
registerMessage("playerInput", "I4s1", {"frame", "inputStates"}, channels.inputUpdates)
registerMessage("playerStateHash", "I4c16", {"frame", "playerStateHash"}, channels.stateHashes)
registerMessage("desyncDetected", "I4", {"frame"})
registerMessage("playerState", "I4s1", {"frame", "playerState"})
registerMessage("rematch", "B", {"rematch"})

-- dummy messages
registerMessage("nop")
registerMessage("disconnect")

return messages
