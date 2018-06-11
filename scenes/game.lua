local scenes = require("scenes")
local players = require("player")
local input = require("input")
local draw = require("draw")
local sounds = require("sounds")
local const = require("const")
local particles = require("particles")
local net = require("net")
local messages = require("net.messages")
local env = require("environment")
local states = require("player.states.states")
local FrameDict = require("util.framedict")

local scene = {name = "game"}

scene.inputDelay = 0

scene.message = "testing"

local playerStates = {
    FrameDict(const.maxSavedPlayerStates),
    FrameDict(const.maxSavedPlayerStates),
}

local remotePlayerStateHashes = {}

local lastUpdateFrame = 0

local localPlayer = nil -- stays nil for local multiplayer
local remotePlayer = nil

local deathStart = nil
local deathFreeze = false

local function assertInputReader()
    assert(true, "This input reader is for remote players only and something went wrong if this was called.")
end

local function getInputBuffer(readInputFunc)
    return input.InputBuffer(const.inputBufferLength, input.inputNames, readInputFunc)
end

local function getLocalInputReader(playerId)
    return input.keyboardInputReader(const.controlSets[env.CONTROL_SET][playerId])
end

local function prepareInputBuffers()
    local inputBuffer1 = getInputBuffer(getLocalInputReader(1))
    local inputBuffer2 = getInputBuffer(getLocalInputReader(2))
    local remoteInputBuffer = getInputBuffer(assertInputReader)

    if net.connected then
        if net.hosting then
            players[1].inputBuffer = inputBuffer1
            players[2].inputBuffer = remoteInputBuffer
        else
            players[1].inputBuffer = remoteInputBuffer
            players[2].inputBuffer = inputBuffer1
        end
    else
        players[1].inputBuffer = inputBuffer1
        players[2].inputBuffer = inputBuffer2
    end
end

function scene.enter()
    players[1] = players.Player(1, const.spawnEdgeDistance)
    players[2] = players.Player(2, const.resX - const.spawnEdgeDistance)

    players[1].isLocal = not net.connected or net.hosting
    players[2].isLocal = not net.connected or not net.hosting
    remotePlayer = net.connected and (net.hosting and players[2] or players[1])
    localPlayer = net.connected and (net.hosting and players[1] or players[2])

    prepareInputBuffers()
end

local function playerScore(player, delta)
    player.score = player.score + (delta or 1)
    draw.blinkScore(player.id)
end

local function explodeDeadPlayers()
    sounds.die:play()
    for _, player in ipairs(players) do
        if player.state.class == states.Dead then
            player.visible = false
            for y = 1, const.playerHeight do
                for x = 1, const.playerWidth do
                    particles.playerExplosion(player.id,
                        player.posX - const.playerWidth/2 + x - 1,
                        player.posY - const.playerHeight + y - 1)
                end
            end
        end
    end
end

local function updateGame(frame)
    lastUpdateFrame = frame

    if deathFreeze then
        if frame - deathStart > const.deathFreezeDuration then
            deathFreeze = false
            explodeDeadPlayers()
        end
    else
        for _, player in ipairs(players) do
            local inputState = player.inputBuffer:getState(frame)
            player:update(inputState)
        end

        local hitPlayers = {}
        for _, player in ipairs(players) do
            if player:checkHit() then
                table.insert(hitPlayers, player)
            end
        end

        if #hitPlayers > 0 then
            deathStart = frame
            deathFreeze = true

            -- both players killed each other simultaneously
            if #hitPlayers == 2 then
                for i = 1, 2 do
                    hitPlayers[i]:die()
                    playerScore(hitPlayers[i])
                end
            elseif #hitPlayers == 1 then
                hitPlayers[1]:die()
                playerScore(hitPlayers[1]:getOpponent())
            end
        end
    end

    if deathStart and frame - deathStart > const.deathDuration then
        players[1]:respawn()
        players[2]:respawn()
        deathStart = nil
    end
end

local function setMessage(msg)
    scene.message = msg or ""
end

function scene.update()
    for i = 1, 2 do
        if players[i].isLocal then
            if deathStart then -- in death animation
                players[i].inputBuffer:setInput(scene.frameCounter, 0) -- all false
            else
                players[i].inputBuffer:readInput(scene.frameCounter)
            end
        end
    end

    if net.connected then
        net.send(messages.playerInput, scene.frameCounter,
            localPlayer.inputBuffer:serialize(const.numNetUpdateInputFrames))

        local msg = net.getMessage()
        while msg do
            if msg.class == messages.playerInput then
                remotePlayer.inputBuffer:deserialize(msg.frame, msg.inputStates)
            elseif msg.class == messages.playerStateHash then
                table.insert(remotePlayerStateHashes, {
                    frame = msg.frame,
                    hash = msg.playerStateHash,
                })
            elseif msg.class == messages.desyncDetected then
                -- TODO: desync recovery
                net.send(messages.playerState, msg.frame,
                    playerStates[localPlayer.id][msg.frame]:serialize())
            elseif msg.class == messages.playerState then
                print("remote state of remote player:", msg.frame,
                    players.PlayerState.deserialize(msg.playerState))
            else
                print("Unknown message:", msg.class.id, msg.class.name)
            end
            msg = net.getMessage()
        end

        local rtt = net.getRtt()
        scene.inputDelay = math.max(const.minInputDelay,
            math.ceil(rtt / 2.0 / 1000 * const.simFps))
    else
        scene.inputDelay = 0
    end

    local updateUntil = scene.frameCounter - scene.inputDelay
    while lastUpdateFrame < updateUntil do
        local updateFrame = lastUpdateFrame + 1
        if players[1].inputBuffer:getFrame(updateFrame) and
                players[2].inputBuffer:getFrame(updateFrame) then
            updateGame(updateFrame)
            setMessage()
            if net.connected then
                playerStates[1]:set(updateFrame, players[1]:fullState())
                playerStates[2]:set(updateFrame, players[2]:fullState())
                net.send(messages.playerStateHash, updateFrame,
                    playerStates[localPlayer.id][updateFrame]:getHash())
            end
        else
            setMessage("WAITING")
            break
        end
    end

    -- check for desync
    for i = #remotePlayerStateHashes, 1, -1 do
        local stateHash = remotePlayerStateHashes[i]
        local playerState = playerStates[remotePlayer.id][stateHash.frame]
        if playerState then
            if playerState:getHash() ~= stateHash.hash then
                print("Desync on frame", stateHash.frame)
                print("local state of remote player", stateHash.frame, playerState)
                setMessage("DESYNC")
                -- TODO: desync recovery
                net.send(messages.desyncDetected, stateHash.frame)
            else
                setMessage()
            end
            table.remove(remotePlayerStateHashes, i)
        end
    end

    net.flush()
end

function scene.draw()
    draw.start()
    draw.game()
    if lk.isDown("f1") then
        draw.help()
    end
    if net.connected then
        local rtt = net.getRtt()
        lg.setColor(1, 1, 1)
        lg.printf(rtt .. "MS " .. scene.inputDelay .. "F" , 0, 1, const.resX, "center")
    end
    draw.finalize()
end

function scene.keypressed(key)
    local ctrl = lk.isDown("lctrl") or lk.isDown("rctrl")
    if key == "h" and ctrl then
        draw.debug = not draw.debug
    end
    if key == "f5" then
        for _, player in ipairs(players) do
            player.score = 0
            player:respawn()
        end
    end
end

function scene.exit()
end

return scene
