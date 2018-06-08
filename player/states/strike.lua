local class = require("util.class")
local const = require("const")
local states = require("player.states.states")
local sounds = require("sounds")

local Strike = class("Strike", states.Base)

function Strike:initialize(player, ...)
    states.Base.initialize(self, player)
end

function Strike:enter()
end

function Strike:exit(newState)
end

function Strike:update()
    local player = self.player
    local ctrl = player.controller

    local dt = player.time - self.start
    for _, anim in ipairs(const.strikeAnimTimes) do
        if dt > anim[2] then
            player:setSword(const.swordPositions.strike[anim[1]])
        end
    end

    if dt >= const.strikeActive[1] and dt <= const.strikeActive[2] then
        if not player.hitbox then
            sounds.strike:play()
            player:setHitbox(const.strikeHitbox)
        end
    else
        player:setHitbox()
    end

    if dt > const.strikeDuration then
        player:exitState()
    end
end

return Strike
