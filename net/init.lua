local enet = require("enet")
local mp = require("libs.MessagePack")

local const = require("const")
local messages = require("net.messages")
local utable = require("util.table")
local scenes = require("scenes")

local net = {}

net.messages = messages

net.hosting = false
net.connected = false

-- server
local serverHost
local clientPeer

-- client
local clientHost
local serverPeer

-- shared
local messageHandlers = {}

messageHandlers[messages.clientHello.id] = function(message, event)
    if clientPeer then
        event.peer:send(messages.hostHello:serialize{success = 0, reason = 0},
            messages.channels.reliable, "reliable")
    else
        -- TODO: Check version
        clientPeer = event.peer
        net.send(messages.hostHello, {
            success = 1,
            reason = 0,
            gameInfo = mp.pack(scenes.game.gameInfo),
        })
        net.connected = true
    end
end

messageHandlers[messages.hostHello.id] = function(message, event)
    if message.success then
        net.connected = true
        scenes.game.gameInfo = mp.unpack(message.gameInfo)
    else
        print("Not connected. Reason:", message.reason)
    end
end

function net.host(gameInfo, port)
    local address = "*"
    port = port or const.defaultPort
    print("Hosting on", address, port)
    serverHost = enet.host_create(address .. ":" .. port, 8, #messages.channels)
    if not serverHost then
        -- TODO: Less drastic error handling
        error(("Could not host on port %d!"):format(port))
    end
    serverHost:compress_with_range_coder()
    net.hosting = true
end

function net.connect(address, port)
    port = port or const.defaultPort
    clientHost = enet.host_create()
    clientHost:compress_with_range_coder()
    print("Connecting to", address, port, "..")
    serverPeer = clientHost:connect(address .. ":" .. port, #messages.channels)
    serverPeer:round_trip_time(const.defaultRtt)
    net.hosting = false
end

function net.reset()
    -- the only way to destroy host instances is to nil them and collectgarbage()
    serverHost = nil
    clientPeer = nil
    clientHost = nil
    serverPeer = nil
    collectgarbage()
    net.hosting = false
    net.connected = false
end

function net.getMessage()
    local host = serverHost or clientHost
    while host do
        local event = host:service()
        if event == nil then return end

        if event.type == "connect" then
            if net.hosting then
                event.peer:round_trip_time(const.defaultRtt)
                -- do nothing yet, wait for messages.clientHello
            else
                -- TODO: version
                net.send(messages.clientHello, "testversion")
            end
        end

        if event.type == "disconnect" then
            if net.hosting then
                -- TODO: disconnect
            else
                -- TODO: disconnect
            end
        end

        if event.type == "receive" then
            -- just ignore packets from everyone else
            if event.peer == serverPeer or not clientPeer or clientPeer == event.peer then
                local msg = messages.deserialize(event.data)
                -- if there is a handler, it can return true to not return the message
                if not messageHandlers[msg.id] or not messageHandlers[msg.id](msg, event) then
                    return msg
                end
            end
        end
    end
end

function net.getRtt()
    local peer = clientPeer or serverPeer
    if peer then
        return peer:round_trip_time()
    end
end

function net.flush()
    local host = clientHost or serverHost
    if host then
        host:flush()
    end
end

function net.send(messageClass, ...)
    local channel = messageClass.channel or messages.channels.reliable
    assert(not clientPeer or not serverPeer)
    local peer = clientPeer or serverPeer
    local data = messageClass:serialize(...)
    if peer:state() == "connected" then
        peer:send(data, channel.id, channel.flag)
    else
        print(("Attempt to send to peer in state '%s'"):format(peer:state()))
    end
end

return net
