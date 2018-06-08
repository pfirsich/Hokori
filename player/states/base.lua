local class = require("util.class")
local scenes = require("scenes")

local PlayerState = class("PlayerState")

function PlayerState:initialize(player)
    self.player = player
    self.start = player.time
end

function PlayerState:enter()
end

function PlayerState:update()
end

function PlayerState:exit(newState)
end

function PlayerState:hit(_type)
    return _type ~= "normal"
end

return PlayerState
