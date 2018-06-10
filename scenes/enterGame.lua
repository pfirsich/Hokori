local scenes = require("scenes")
local draw = require("draw")
local sounds = require("sounds")
local const = require("const")
local net = require("net")
local messages = require("net.messages")

local scene = {name = "enterGame"}

local exitTime

function scene.enter(delay)
    exitTime = love.timer.getTime() + (delay or 3.0)
end

function scene.update()
    if exitTime < love.timer.getTime() then
        scenes.enter(scenes.game)
    end
end

function scene.draw()
    draw.start()
    draw.menuBase(true)

    lg.setColor(1, 1, 1)
    local dt = exitTime - love.timer.getTime()
    local text = "FIGHT!"
    if dt > 1 then
        text = tostring(math.floor(dt))
    end
    lg.printf(text, 0, 20, const.resX, "center")

    draw.finalize()
end

function scene.keypressed(key)
end

function scene.exit()
end

return scene
