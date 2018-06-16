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

-- accessed and modified from a number of places (bad design)
scene.gameInfo = {
    firstTo = nil,
}

local inputDelay
local hudMessage

local playerStates
local remotePlayerStateHashes

local lastUpdateFrame

local localPlayer
local remotePlayer

local deathStart
local deathFreeze

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
    assert(scene.gameInfo.firstTo)

    inputDelay = 0
    hudMessage = ""

    playerStates = {
        FrameDict(const.maxSavedPlayerStates),
        FrameDict(const.maxSavedPlayerStates),
    }
    remotePlayerStateHashes = {}

    frameCounter = 1
    lastUpdateFrame = 0
    localPlayer = nil -- stays nil for local multiplayer
    remotePlayer = nil
    deathStart = nil
    deathFreeze = false

    particles.clear()

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
        deathStart = nil

        if players[1].score >= scene.gameInfo.firstTo then
            scenes.enter(scenes.playerWins, "PLAYER 1")
            return
        elseif players[2].score >= scene.gameInfo.firstTo then
            scenes.enter(scenes.playerWins, "PLAYER 2")
            return
        end

        players[1]:respawn()
        players[2]:respawn()
    end
end

local function readInput(frameCounter)
    for i = 1, 2 do
        if players[i].isLocal then
            if deathStart then -- in death animation
                players[i].inputBuffer:setInput(frameCounter, 0) -- all false
            else
                players[i].inputBuffer:readInput(frameCounter)
            end
        end
    end
end

local function processNetMessages()
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
end

local function getInputDelay(rtt)
    return math.max(const.minInputDelay, math.ceil(rtt / 2.0 / 1000 * const.simFps))
end

local function savePlayerStates(frame)
    playerStates[1]:set(frame, players[1]:fullState())
    playerStates[2]:set(frame, players[2]:fullState())
    net.send(messages.playerStateHash, frame, playerStates[localPlayer.id][frame]:getHash())
end

local function checkForDesync()
    for i = #remotePlayerStateHashes, 1, -1 do
        local stateHash = remotePlayerStateHashes[i]
        local playerState = playerStates[remotePlayer.id][stateHash.frame]
        if playerState then
            if playerState:getHash() ~= stateHash.hash then
                print("Desync on frame", stateHash.frame)
                print("local state of remote player", stateHash.frame, playerState)
                hudMessage = "DESYNC"
                -- TODO: desync recovery
                net.send(messages.desyncDetected, stateHash.frame)
            else
                hudMessage = ""
            end
            table.remove(remotePlayerStateHashes, i)
        end
    end
end

function scene.update()
    readInput(frameCounter)

    if net.connected then
        net.send(messages.playerInput, frameCounter,
            localPlayer.inputBuffer:serialize(const.numNetUpdateInputFrames))

        -- reads remote players input, saves state hashes and responds to desync
        -- notifications with debug info
        processNetMessages()

        inputDelay = getInputDelay(net.getRtt())
    end

    hudMessage = ""
    local updateUntil = frameCounter - inputDelay
    while lastUpdateFrame < updateUntil do
        local updateFrame = lastUpdateFrame + 1
        if players[1].inputBuffer:getFrame(updateFrame) and
                players[2].inputBuffer:getFrame(updateFrame) then
            updateGame(updateFrame)
            lastUpdateFrame = updateFrame

            if net.connected then
                savePlayerStates(updateFrame)
            end
        else
            hudMessage = "WAITING"
            break
        end
    end

    checkForDesync()

    net.flush()

    frameCounter = frameCounter + 1
end

function scene.draw()
    draw.start()
    draw.game()
    if lk.isDown("f1") then
        draw.help()
    end
    lg.setColor(1, 1, 1)
    if net.connected and hudMessage == "" then
        local rtt = net.getRtt()
        hudMessage = rtt .. "MS " .. inputDelay .. "F"
        --lg.printf(rtt .. "MS " .. inputDelay .. "F" , 0, 1, const.resX, "center")
    end
    lg.printf(hudMessage, 0, const.topBarHeight + 1, const.resX, "center")
    lg.printf("FT " .. scene.gameInfo.firstTo, 0, 1, const.resX, "center")
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
