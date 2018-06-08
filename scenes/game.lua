local scenes = require("scenes")
local players = require("player")
local input = require("input")
local draw = require("draw")
local sounds = require("sounds")
local const = require("const")
local particles = require("particles")

local scene = {name = "game"}

local deathStart = nil
local deathFreeze = false

function scene.enter(mapFileName, _client)
    players[1] = players.Player(1, input.controllers[1], true)
    players[2] = players.Player(2, input.controllers[2], false)
    draw.initGame()
end

local function playerScore(player)
    player:uncontrol()
    player.score = player.score + 1
    draw.blinkScore(player.id)
end

local function playerDeath(player)
    player:die()
end

local function explodePlayers()
    sounds.die:play()
    for _, player in ipairs(players) do
        if player.dead then
            player.visible = false
            for y = 1, const.playerHeight do
                for x = 1, const.playerWidth do
                    particles.playerExplosion(player.id,
                        player.posX - const.playerWidth/2 + x,
                        player.posY - const.playerHeight + y)
                end
            end
        end
    end
end

function scene.update()
    if deathFreeze then
        if now() - deathStart > const.deathFreezeDuration then
            deathFreeze = false
            explodePlayers()
        end
    else
        input.update()
        for _, player in ipairs(players) do
            if not player.dead then
                player:update()
            end
        end

        local hitPlayers = {}
        for _, player in ipairs(players) do
            if player:checkHit() then
                table.insert(hitPlayers, player)
            end
        end

        if #hitPlayers > 0 then
            deathStart = now()
            deathFreeze = true

            -- both players killed each other simultaneously
            if #hitPlayers == 2 then
                for i = 1, 2 do
                    playerDeath(hitPlayers[i])
                    playerScore(hitPlayers[i])
                end
            elseif #hitPlayers == 1 then
                local deadPlayer = hitPlayers[1]
                local opponent = deadPlayer:getOpponent()
                playerDeath(deadPlayer)
                playerScore(opponent)
            end
        end
    end

    if deathStart and now() - deathStart > const.deathDuration then
        players[1]:respawn()
        players[2]:respawn()
        deathStart = nil
    end
end

function scene.draw()
    draw.game()
end

function scene.keypressed(key)
    local ctrl = lk.isDown("lctrl") or lk.isDown("rctrl")
    if key == "h" and ctrl then
        draw.debug = not draw.debug
    end
end

function scene.exit()
end

return scene