local class = require("util.class")
local const = require("const")
local states = require("player.states.states")

local Normal = class("Normal", states.Base)

function Normal:initialize(player, ...)
    states.Base.initialize(self, player)
end

function Normal:enter()
    self.player:setSword(const.swordPositions.normal)
end

function Normal:exit(newState)
end

function Normal:update()
    local player = self.player
    local ctrl = player.controller

    if ctrl.forward.state then
        player.posX = player.posX + player.forwardDir * const.walkForwardVel
    end

    if ctrl.action1.pressed then
        player:setState(states.Strike)
        return
    end

    if ctrl.action2.pressed then
        player:setState(states.Tackle)
        return
    end

    if ctrl.forward.pressed and ctrl.forward:inHistory("pressed", const.dashInputWindow) then
        player:setState(states.Dash, true)
        return
    end

    if ctrl.backward.pressed and ctrl.backward:inHistory("pressed", const.dashInputWindow) and
            not ctrl.forward.state then
        player:setState(states.Dash, false)
        return
    end

    if states.Block.tryEnter(player) then
        return
    end
end

function Normal:hit(_type)
    if _type == "tackle" then
        self.player:getOpponent():die()
    else
        states.Base.hit(self, _type)
    end
end

return Normal
