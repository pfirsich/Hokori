local class = require("util.class")
local const = require("const")
local states = require("player.states.states")

local Dash = class("Dash", states.Base)

function Dash:initialize(player, ...)
    states.Base.initialize(self, player)
end

function Dash:enter(forward)
    self.forward = forward
    self.direction = forward and self.player.forwardDir or self.player.backwardDir
    self.velocity = self.direction * (forward and const.dashFowardVel or const.dashBackwardVel)
end

function Dash:exit(newState)
end

function Dash:update(dt)
    local player = self.player
    local ctrl = player.controller

    player.posX = player.posX + self.velocity

    if (now() - self.start > const.dashCancelAfter and ctrl.down.pressed) or
            now() - self.start >= const.dashDuration then
        if self.forward then
            -- if you forward dash and hold block immediately, you will go into Normal for one frame
            player:setState(states.Normal)
        else
            player:exitState()
        end
        return
    end
end

return Dash
