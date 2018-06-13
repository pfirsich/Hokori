-- intentional globals
lg = love.graphics
lf = love.filesystem
lm = love.math
lk = love.keyboard
ld = love.data
inspect = require("libs.inspect")

local flaschentaschen = require("libs.flaschentaschen")

local env = require("environment")
local draw = require("draw")
local players = require("player")
local const = require("const")
local scenes = require("scenes")

local nextUpdate = -1
local frameCounter = 0

function now()
    return frameCounter
end

function love.load(arg)
    draw.setWindowSize()
    draw.initBackground()

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

    if arg[1] == "--host" then
        scenes.enter(scenes.hostGame)
    elseif arg[1] == "--connect" then
        scenes.enter(scenes.joinGame, arg[2])
    else
        scenes.enter(scenes[env.ENTRY_SCENE])
    end
end

function love.update()
    if nextUpdate > love.timer.getTime() then
        return
    end
    nextUpdate = love.timer.getTime() + 1.0/const.simFps

    frameCounter = frameCounter + 1
    scenes.current.frameCounter = scenes.current.frameCounter + 1
    if scenes.current.update then
        scenes.current.update()
    end
end

function love.draw()
    if scenes.current.draw then
        scenes.current.draw()
    end
end

function love.keypressed(...)
    if scenes.current.keypressed then
        scenes.current.keypressed(...)
    end

    local key = select(1, ...)
    if key == "f" and (lk.isDown("lctrl") or lk.isDown("rctrl")) then
        flaschentaschen.saveLastFrame("frame.ppm")
    end
end
