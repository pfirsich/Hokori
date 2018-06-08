local class = require("util.class")
local const = require("const")
local states = require("player.states.states")
local scenes = require("scenes")

local Dead = class("Dead", states.Base)

function Dead:initialize(player, ...)
    states.Base.initialize(self, player)
end

function Dead:enter()
end

function Dead:exit(newState)
end

function Dead:update()
end

function Dead:hit(_type)
    -- ignore all
end

return Dead
