local scenes = require("scenes")
local draw = require("draw")
local sounds = require("sounds")
local const = require("const")
local Menu = require("util.menu")
local env = require("environment")
local net = require("net")
local util = require("util")
local players = require("player")

local scene = {name = "playerWins"}

local showMenuAfter
local winner

local rematch
local opponentRematch

local function toMenu()
    scenes.enter(scenes.mainmenu)
end

local function menuFunc(acceptRematch)
    rematch = acceptRematch
    if net.connected then
        net.send(net.messages.rematch, acceptRematch and 1 or 0)
        net.flush() -- send in case we go to menu
    else
        if acceptRematch then
            scenes.enter(scenes.chooseMode, scenes.enterGame, 1)
        end
    end
    -- leave anyways
    if not acceptRematch then
        toMenu()
    end
end

local menu = Menu({
    {title = env.STAB_MODE and "PLAY AGAIN" or "SALTY RUNBACK", func = function() menuFunc(true) end},
    not env.STAB_MODE and {title = "RAGE QUIT", func = function() menuFunc(false) end} or nil,
}, 1)

function scene.enter(_winner)
    showMenuAfter = love.timer.getTime() + 2.0
    winner = _winner

    rematch = nil
    opponentRematch = nil
end

function scene.update()
    local msg = net.getMessage()
    while msg do
        if msg.class == net.messages.rematch then
            opponentRematch = msg.rematch > 0
        else
            print("Unknown message:", msg.class.id, msg.class.name)
        end
        msg = net.getMessage()
    end

    if net.connected then
        if rematch == true and opponentRematch == true then
            scenes.enter(scenes.enterGame, 1)
        elseif (rematch ~= nil and opponentRematch ~= nil) or opponentRematch == false then
            toMenu()
        end
    end
end

local function winnerScore()
    local score1 = players[1].score
    local score2 = players[2].score
    return math.max(score1, score2) .. " - " .. math.min(score1, score2)
end

function scene.draw()
    draw.start()
    draw.menuBase()
    if showMenuAfter < love.timer.getTime() then
        if rematch == nil then
            menu:draw()
        else
            lg.printf("WAITING FOR OTHER PLAYER" .. util.dotString(3), 0, 20, const.resX, "center")
        end
    else
        lg.printf(winner .. " WINS!\n" .. winnerScore(), 0, 20, const.resX, "center")
    end
    draw.finalize()
end

function scene.keypressed(key)
    if showMenuAfter < love.timer.getTime() and rematch == nil then
        menu:keypressed(key)
    end
end

function scene.exit()
end

return scene
