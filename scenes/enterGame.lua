local scenes = require("scenes")
local draw = require("draw")
local sounds = require("sounds")
local const = require("const")
local net = require("net")
local messages = require("net.messages")
local net = require("net")

local scene = {name = "enterGame"}

local exitTime
local soundPlayed

function scene.enter(delay)
    soundPlayed = false
    exitTime = love.timer.getTime() + (net.connected and 2.5 or 1)
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
    else
        if not soundPlayed then
            soundPlayed = true
            sounds.fight:play()
        end
    end
    lg.printf(text, 0, 20, const.resX, "center")

    draw.finalize()
end

function scene.keypressed(key)
end

function scene.exit()
end

return scene
