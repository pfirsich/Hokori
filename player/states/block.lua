local class = require("util.class")
local const = require("const")
local states = require("player.states.states")
local sounds = require("sounds")
local particles = require("particles")

local Block = class("Block", states.Base)

function Block:initialize(player, ...)
    states.Base.initialize(self, player)
end

function Block.tryEnter(player)
    if player.controller.backward:down() and not player.controller.forward:down() then
        player:setState(states.Block)
        return true
    end
    return false
end

function Block:enter()
end

function Block:exit(newState)
end

function Block:update()
    local player = self.player
    local ctrl = player.controller

    if not ctrl.backward:down() or ctrl.forward:down() then
        player:setState(states.Normal)
        return
    end

    if ctrl.action1:pressed() then
        player:setState(states.Strike)
        return
    end

    if ctrl.action2:pressed() then
        player:setState(states.Tackle)
        return
    end

    if ctrl.down:down() and not ctrl.up:down() then
        self.player:setSword(const.swordPositions.blockLow)
    else
        player.posX = player.posX + player.backwardDir * const.walkBackwardVel
        self.player:setSword(const.swordPositions.block)
    end
end

function Block:hit(_type)
    if _type == "strike" then
        for i = 1, const.blockParticleNum do
            particles.block(self.player)
        end
        sounds.strikeBlock:play()
    else
        return states.Base.hit(self, _type)
    end
end

return Block
