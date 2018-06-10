local const = require("const")
local class = require("util.class")
local umath = require("util.math")
local sounds = require("sounds")
local states_ = require("player.states")
local states = require("player.states.states")

local players = {}

-- assuming I lose all information about the simulation (including past inputs),
-- this function returns everything I need to have the same (next) simulation step
-- give exactly the same results as if I didn't lose it.
local PlayerState = class("PlayerState")
players.PlayerState = PlayerState

PlayerState.format = "<I2I4 BdI4I4 B"

function PlayerState.deserialize(str)
    local values = {ld.unpack(PlayerState.format, str)}
    return PlayerState{
        score = values[1],
        time = values[2],
        visible = values[3] > 0,
        posX = values[4],
        hitboxCounter = values[5],
        lastHitBy = values[6],
        state = {id = values[7]},
    }
end

function PlayerState:initialize(player)
    self.score = player.score
    self.time = player.time
    self.visible = player.visible
    self.posX = player.posX
    self.hitboxCounter = player.hitboxCounter
    self.lastHitBy = player.lastHitBy
    self.stateId = player.state.id -- TODO: more state serialization

    -- After this class is constructed, it remains constant, so we can cache these!
    self.serialization = nil
    self.hash = nil
end

function PlayerState:serialize()
    if not self.serialization then
        self.serialization = ld.pack("string", self.format, self.score, self.time,
            self.visible and 1 or 0, self.posX, self.hitboxCounter, self.lastHitBy,
            self.stateId)
    end
    return self.serialization
end

function PlayerState:getHash()
    if not self.hash then
        self.hash = ld.hash("md5", self:serialize())
    end
    return self.hash
end

function PlayerState:__tostring()
    return ("score: %d, time: %d, v: %s, pos: %f, hbC: %d, lHb: %d, state: %d"):format(
        self.score, self.time, tostring(self.visible), self.posX, self.hitboxCounter,
        self.lastHitBy, self.stateId)
end

local PlayerClass = class("Player")
players.Player = PlayerClass

function PlayerClass:initialize(playerId, spawnPos)
    -- fixed from the start
    self.id = playerId

    self.posY = const.resY - 2
    self.spawnPosX = spawnPos
    self.color = const.playerColors[self.id]

    -- everything below here changes
    self.score = 0
    self.time = 0
    self.visible = true

    self.posX = self.spawnPosX
    self:setDir(spawnPos < const.resX / 2)
    self.sword = {
        offset = {0, 0},
        angle = 0,
        length = 0,
    }
    self.hitbox = nil
    self.hitboxCounter = 0
    self.lastHitBy = -1
    self:setState(states.Normal)
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
end

function PlayerClass:fullState()
    return PlayerState(self)
end

function PlayerClass:setHitbox(hitbox)
    if hitbox == nil then
        self.hitbox = nil
    else
        self.hitbox = {
            id = self.hitboxCounter,
            _type = hitbox[1],
            x = hitbox[2], y = hitbox[3],
            w = hitbox[4], h = hitbox[5],
        }
        self.hitboxCounter = self.hitboxCounter + 1
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
    self:updateDir()
    self.hitbox = nil
    self:setState(states.Normal)
    self.visible = true
end

function PlayerClass:die()
    self:setState(states.Dead)
end

function PlayerClass:checkHit()
    local opp = self:getOpponent()
    if opp.hitbox and opp.hitbox.id > self.lastHitBy then
        local hbX, hbY, hbW, hbH = opp:getWorldHitbox()
        if umath.aabbIntersect(hbX, hbY, hbW, hbH, self:getWorldRect()) then
            self.lastHitBy = opp.hitbox.id
            return self.state:hit(opp.hitbox._type)
        end
    end
end

function PlayerClass:update(inputState)
    self.time = self.time + 1

    if self.forwardDir > 0 then
        inputState.forward = inputState.right
        inputState.backward = inputState.left
    else
        inputState.forward = inputState.left
        inputState.backward = inputState.right
    end
    self.controller = inputState

    self.state:update()
    self.posX = math.min(const.levelMaxX, math.max(const.levelMinX, self.posX))
    self:updateDir()
end

return players
