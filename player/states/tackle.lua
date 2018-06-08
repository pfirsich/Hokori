local class = require("util.class")
local const = require("const")
local states = require("player.states.states")

local Tackle = class("Tackle", states.Base)

function Tackle:initialize(player, ...)
    states.Base.initialize(self, player)
end

function Tackle:enter()
    self.velocity = self.player.forwardDir * const.tackleVel
    self.player:setSword(const.swordPositions.tackle)
end

function Tackle:exit(newState)
end

function Tackle:update(dt)
    local player = self.player
    local ctrl = player.controller

    local dt = now() - self.start

    if dt > const.tackleDelay and dt <= const.tackleActive[2] then
        player.posX = player.posX + self.velocity
    end

    if dt >= const.tackleActive[1] and dt <= const.tackleActive[2] then
        player:setHitbox(unpack(const.tackleHitbox))
    else
        player:setHitbox()
    end

    if dt > const.tackleDuration then
        player:exitState()
        return
    end
end

return Tackle
