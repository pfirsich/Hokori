-- this file contains a lot of constants (not moved to const.lua)
-- because the behaviour (code) of the particles is imho just as part of the data/constants
-- as the numbers.
-- => I consider this whole file constants/configuration/data

local const = require("const")
local umath = require("util.math")

local particles = {}

local lerp = umath.lerp
local randf = umath.randf
local dtMultiply = umath.dtMultiply
local deg2rad = umath.deg2rad

local function updatePlayerExplosionParticle(self, dt)
    local maxAge = 6.0
    self.age = self.age + dt

    local decolorTime = 2.0
    if self.age < decolorTime then
        local colorLerp = math.min(1, self.age/decolorTime)
        for c = 1, 3 do
            self.color[c] = lerp(self.startColor[c], self.endColor[c], colorLerp)
        end

        local factor = dtMultiply(0.3, dt)
        self.vx = self.vx * factor
        self.vy = self.vy * factor

        if self.y > const.resY - 2 then
            self.y = const.resY - 2
            self.vy = -self.vy
        end
    else
        self.color[4] = 1.0 - (self.age - decolorTime) / (maxAge - decolorTime)

        local gravAngle = deg2rad(const.dustMoveAngle) + deg2rad(const.dustAngleDelta)*randf(-1, 1)
        self.x = self.x + math.cos(gravAngle) * const.dustFrontSpeed * dt
        self.y = self.y + math.sin(gravAngle) * const.dustFrontSpeed * dt

        if self.y >= const.resY - 2 then
            self.y = const.resY - 2
            self.age = self.age + dt -- age twice as fast on the ground
        end
    end

    if self.age >= maxAge then
        return true
    end
end

function particles.playerExplosion(id, x, y)
    local part = {}
    part.x = x
    part.y = y
    part.startColor = const.playerColors[id]
    local c = lm.random()
    part.endColor = {c, c, c}
    part.color = {}
    local angle = randf(0, 2.0 * math.pi)
    local speed = randf(20, 30)
    part.vx = math.cos(angle) * speed
    part.vy = math.sin(angle) * speed
    part.age = 0
    part.update = updatePlayerExplosionParticle
    table.insert(particles, part)
end

local function updateBlockParticle(self, dt)
    self.age = self.age + dt

    local maxAge = 0.3
    local fadeoutTime = 0.0
    self.color[4] = 1.0 - math.max(0, self.age - fadeoutTime) / (maxAge - fadeoutTime)

    if self.age > maxAge then
        return true
    end
end

function particles.block(player)
    local x = const.playerWidth/2 + 3
    local y = player.posY - const.playerHeight - 1
    if player.forwardDir < 0 then
        x = -x
    end
    x = player.posX + x

    local part = {}
    part.x = x
    part.y = y
    part.color = {0, 0, 1, 0.5}
    local angle = randf(0, 2.0 * math.pi)
    local speed = randf(15, 30)
    part.vx, part.vy = math.cos(angle) * speed, math.sin(angle) * speed
    part.age = 0
    part.update = updateBlockParticle
    table.insert(particles, part)
end

function particles.updateAndDraw(dt)
    -- update
    for i = #particles, 1, -1 do
        local part = particles[i]
        if part:update(dt) then
            table.remove(particles, i)
        end
        part.x = part.x + part.vx * dt
        part.y = part.y + part.vy * dt
    end

    -- draw
    for i, part in ipairs(particles) do
        lg.setColor(part.color)
        lg.rectangle("fill", part.x, part.y, 1, 1)
    end
end

function particles.clear()
    for i = #particles, 1, -1 do
        table.remove(particles, i)
    end
end

return particles
