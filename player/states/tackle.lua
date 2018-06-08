local class = require("util.class")
local const = require("const")
local states = require("player.states.states")
local sounds = require("sounds")

local Tackle = class("Tackle", states.Base)

function Tackle:initialize(player, ...)
    states.Base.initialize(self, player)
end

function Tackle:enter()
    self.velocity = self.player.forwardDir * const.tackleVel
    self.player:setSword(const.swordPositions.tackle)
    self.soundPlayed = false
end

function Tackle:exit(newState)
end

function Tackle:update(dt)
    local player = self.player
    local ctrl = player.controller

    local dt = player.time - self.start

    if dt > const.tackleDelay and dt <= const.tackleActive[2] then
        if not self.soundPlayed then
            sounds.tackle:play()
            self.soundPlayed = true
        end
        player.posX = player.posX + self.velocity
    end

    if dt >= const.tackleActive[1] and dt <= const.tackleActive[2] then
        if not player.hitbox then
            player:setHitbox(const.tackleHitbox)
        end
    else
        player:setHitbox()
    end

    if dt > const.tackleDuration then
        player:exitState()
        return
    end
end

function Tackle:hit(_type)
    if _type == "normal" then
        return true
    else
        return states.Base.hit(self, _type)
    end
end

return Tackle
