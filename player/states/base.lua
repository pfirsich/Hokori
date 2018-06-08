local class = require("util.class")

local PlayerState = class("PlayerState")

function PlayerState:initialize(player)
    self.player = player
    self.start = now()
end

function PlayerState:enter()
end

function PlayerState:update()
end

function PlayerState:exit(newState)
end

function PlayerState:hit(_type)
    self.player:die()
end

return PlayerState
