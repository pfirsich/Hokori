local class = require("util.class")
local const = require("const")
local states = require("player.states.states")

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

    local dt = now() - self.start
    for _, anim in ipairs(const.strikeAnimTimes) do
        if dt > anim[2] then
            player:setSword(const.swordPositions.strike[anim[1]])
        end
    end

    if dt >= const.strikeActive[1] and dt <= const.strikeActive[2] then
        player:setHitbox(unpack(const.strikeHitbox))
    else
        player:setHitbox()
    end

    if dt > const.strikeDuration then
        player:exitState()
    end
end

return Strike
