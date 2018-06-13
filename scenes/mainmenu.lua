local scenes = require("scenes")
local draw = require("draw")
local sounds = require("sounds")
local const = require("const")
local Menu = require("util.menu")
local net = require("net")

local scene = {name = "mainmenu"}

local menu = Menu({
    {title = "LOCAL MULTIPLAYER", func = function()
        scenes.enter(scenes.chooseMode, scenes.enterGame, 1)
    end},
    --{title = "MATCHMAKING", "matchmaking"},
    {title = "HOST PRIVATE GAME", func = function()
        scenes.enter(scenes.chooseMode, scenes.hostGame)
    end},
    {title = "CONNECT", func = function()
        scenes.enter(scenes.joinGame)
    end},
    {title = "QUIT", func = function()
        love.event.quit()
    end},
})

function scene.enter()
    net.reset()
end

function scene.update()
end

function scene.draw()
    draw.start()
    draw.menuBase()
    menu:draw()
    draw.finalize()
end

function scene.keypressed(key)
    menu:keypressed(key)
end

function scene.exit()
end

return scene
