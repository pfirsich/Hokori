-- intentional globals
lg = love.graphics
lf = love.filesystem
lm = love.math
lk = love.keyboard
inspect = require("libs.inspect")

local flaschentaschen = require("libs.flaschentaschen")

local env = require("environment")
local input = require("input")
local draw = require("draw")
local players = require("player")
local const = require("const")
local scenes = require("scenes")

local nextUpdate = 0
local frameCounter = 0

function now()
    return frameCounter
end

function love.load()
    draw.setWindowSize()

    if env.FLASCHENTASCHEN then
        flaschentaschen.initialize(const.resX * const.resY, env.FT_IP, env.FT_PORT)
    end

    scenes.import()
    for name, scene in pairs(scenes.list) do
        scene.frameCounter = 0
        if scene.load then
            scene.load()
        end
    end

    scenes.enter(scenes.game)
end

function love.update()
    if nextUpdate > love.timer.getTime() then
        return
    end
    nextUpdate = love.timer.getTime() + 1.0/const.simFps

    frameCounter = frameCounter + 1
    scenes.current.frameCounter = scenes.current.frameCounter + 1
    scenes.current.update()
end

function love.draw()
    scenes.current.draw()
end

function love.keypressed(...)
    if scenes.current.keypressed then
        scenes.current.keypressed(...)
    end
end
