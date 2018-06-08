local const = require("const")
local class = require("util.class")
local umath = require("util.math")
local input = require("input")
local states_ = require("player.states")
local states = require("player.states.states")

local players = {}

local PlayerClass = class("Player")
players.Player = PlayerClass

function PlayerClass:initialize(playerId, controller, leftSide)
    self.id = playerId
    self.controller = controller

    self.score = 0
    self.posY = const.resY - 2
    self.spawnPosX = ({const.spawnEdgeDistance, const.resX - const.spawnEdgeDistance})[self.id]
    self.color = const.playerColors[self.id]

    self.posX = self.spawnPosX
    self:setDir(leftSide)
    self.sword = {
        offset = {0, 0},
        angle = 0,
        length = 0,
    }
    self.hitbox = nil
    self:setState(states.Normal)
end

function PlayerClass:setHitbox(_type, x, y, w, h)
    if _type == nil then
        self.hitbox = nil
    else
        self.hitbox = {
            _type = _type,
            x = x, y = y,
            w = w, h = h,
        }
    end
end

function PlayerClass:getWorldHitbox()
    if self.hitbox then
        local x, y, w, h = self.hitbox.x, self.hitbox.y, self.hitbox.w, self.hitbox.h
        if self.forwardDir < 0 then
            x = -(x + w)
        end
        return x + self.posX, y + self.posY, w, h
    end
end

function PlayerClass:setState(stateClass, ...)
    local state = stateClass(self)
    if self.state then
        self.state:exit(state)
    end
    self.state = state
    self.state:enter(...)
end

function PlayerClass:updateDir()
    local opp = self:getOpponent()
    self:setDir(self.posX < opp.posX)
end

function PlayerClass:setDir(leftSide)
    self.forwardDir = leftSide and 1 or -1
    self.backwardDir = -self.forwardDir
    if leftSide then
        self.controller.forward = self.controller.right
        self.controller.backward = self.controller.left
    else
        self.controller.forward = self.controller.left
        self.controller.backward = self.controller.right
    end
end

function PlayerClass:getWorldRect()
    -- player position is in the center of the bottom edge
    return self.posX - const.playerWidth/2,
           self.posY - const.playerHeight,
           const.playerWidth, const.playerHeight
end

function PlayerClass:setSword(cfg)
    self.sword.offset[1] = cfg[1]
    self.sword.offset[2] = cfg[2]
    self.sword.angle = cfg[3]
    self.sword.length = cfg[4] or const.swordLength
end

function PlayerClass:exitState()
    if not states.Block.tryEnter(self) then
        self:setState(states.Normal)
    end
end

function PlayerClass:getOpponent()
    return players[3 - self.id]
end

function PlayerClass:respawn()
    self.posX = self.spawnPosX
    self:updateDir(leftSide)
    self.hitbox = nil
    self:setState(states.Normal)
end

function PlayerClass:die()
    local opp = self:getOpponent()
    opp.score = opp.score + 1
    self:respawn()
    opp:respawn()
end

function PlayerClass:update()
    self.state:update()
    self.posX = math.min(const.levelMaxX, math.max(const.levelMinX, self.posX))

    local opp = self:getOpponent()
    if opp.hitbox then
        local hbX, hbY, hbW, hbH = opp:getWorldHitbox()
        if umath.aabbIntersect(hbX, hbY, hbW, hbH, self:getWorldRect()) then
            self.state:hit(opp.hitbox._type)
        end
    end

    self:updateDir()
end

return players
