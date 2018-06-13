local scenes = require("scenes")
local draw = require("draw")
local sounds = require("sounds")
local const = require("const")
local Menu = require("util.menu")

local scene = {name = "chooseMode"}

local nextScene
local nextSceneArgs

local function chooseOption(firstTo)
    scenes.game.gameInfo.firstTo = firstTo
    scenes.enter(nextScene, unpack(nextSceneArgs))
end

local menu = Menu({
    {title = "FT 10", func = function() chooseOption(10) end},
    {title = "FT 15", func = function() chooseOption(15) end},
    {title = "FT 20", func = function() chooseOption(20) end},
    {title = "FT 30", func = function() chooseOption(30) end},
}, 2)

function scene.enter(_nextScene, ...)
    nextScene = _nextScene or scenes.enterGame
    nextSceneArgs = {...}
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
