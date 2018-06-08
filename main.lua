-- intentional globals
lg = love.graphics
lf = love.filesystem
lm = love.math
inspect = require("libs.inspect")

local input = require("input")
local draw = require("draw")
local players = require("player")
local const = require("const")

function love.load()
    players[1] = players.Player(1, input.controllers[1], true)
    players[2] = players.Player(2, input.controllers[2], false)

    draw.init()
end

local nextUpdate = 0
local frameCounter = 0
function love.update(dt)
    if nextUpdate > love.timer.getTime() then
        return
    end
    nextUpdate = love.timer.getTime() + 1.0/const.simFps

    input.update()
    for _, player in ipairs(players) do
        player:update()
    end

    frameCounter = frameCounter + 1
end

function now()
    return frameCounter
end
