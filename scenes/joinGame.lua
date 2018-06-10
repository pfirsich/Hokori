local scenes = require("scenes")
local draw = require("draw")
local sounds = require("sounds")
local const = require("const")
local net = require("net")
local messages = require("net.messages")
local util = require("util")

local scene = {name = "joinGame"}

function scene.enter()
    net.connect("localhost")
end

function scene.update()
    local msg = net.getMessage()
    while msg do
        -- do nothing
        msg = net.getMessage()
    end

    if net.connected then
        scenes.enter(scenes.enterGame)
    end
end

function scene.draw()
    draw.start()
    draw.menuBase()

    lg.setColor(1, 1, 1)
    local text = "CONNECTING" .. util.dotString(3)
    lg.printf(text, 0, 20, const.resX, "center")

    draw.finalize()
end

function scene.keypressed(key)
end

function scene.exit()
end

return scene

