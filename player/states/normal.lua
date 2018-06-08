local class = require("util.class")
local const = require("const")
local states = require("player.states.states")
local scenes = require("scenes")

local Normal = class("Normal", states.Base)

function Normal:initialize(player, ...)
    states.Base.initialize(self, player)
end

function Normal:enter()
    self.player:setSword(const.swordPositions.normal)
end

function Normal:exit(newState)
    self.player:setHitbox()
end

function Normal:update()
    local player = self.player
    local ctrl = player.controller

    -- re-set the hitbox every frame, so id is renewed
    self.player:setHitbox(const.normalHitbox)

    if ctrl.forward.state then
        player.posX = player.posX + player.forwardDir * const.walkForwardVel
    end

    if ctrl.action1:inHistory("pressed", const.attackBufferFrames) then
        player:setState(states.Strike)
        return
    end

    if ctrl.action2:inHistory("pressed", const.attackBufferFrames) then
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
        -- ignore
    else
        return states.Base.hit(self, _type)
    end
end

return Normal
