local const = require("const")

local particles = {}

local function lerp(a, b, t)
    return (1 - t) * a + t * b
end

local function randf(a, b)
    return lerp(a, b, lm.random())
end

local function dtMultiply(factor, dt)
    return math.exp(math.log(factor) * dt)
end

local function updatePlayerExplosionParticle(self, dt)
    local maxAge = 8.0
    self.age = self.age + dt

    local decolorTime = 2.0
    local colorLerp = math.min(1, self.age/decolorTime)
    if self.age < decolorTime then
        for c = 1, 3 do
            self.color[c] = lerp(self.startColor[c], self.endColor[c], colorLerp)
        end
    else
        self.color[4] = 1.0 - (self.age - decolorTime) / (maxAge - decolorTime)
    end

    local gravAngle = math.pi*0.75 + math.pi*0.1*randf(-1, 1)
    local gravSpeed = 2
    self.x = self.x + math.cos(gravAngle) * gravSpeed * dt
    self.y = self.y + math.sin(gravAngle) * gravSpeed * dt

    local factor = dtMultiply(0.3, dt)
    self.vx = self.vx * factor
    self.vy = self.vy * factor

    if self.y > const.resY - 2 then
        self.y = const.resY - 2
        self.vy = -self.vy
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
    part.vx, part.vy = math.cos(angle) * speed, math.sin(angle) * speed
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

function particles.update(dt)
    local remove = {}
    for i, part in ipairs(particles) do
        remove[i] = part:update(dt)
        part.x = part.x + part.vx * dt
        part.y = part.y + part.vy * dt
    end

    for i, v in ipairs(remove) do
        if v then
            table.remove(particles, i)
        end
    end
end

function particles.draw()
    for i, part in ipairs(particles) do
        lg.setColor(part.color)
        lg.rectangle("fill", part.x, part.y, 1, 1)
    end
end

return particles
