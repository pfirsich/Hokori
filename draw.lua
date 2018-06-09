-- This file is a mess

local const = require("const")
local players = require("player")
local particles = require("particles")

local draw = {}

draw.debug = false

lg.setDefaultFilter("nearest", "nearest")
local font = lg.newImageFont("font3x5.png", " 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ.,_!?-:;()+", 1)
lg.setFont(font)

local canvas = lg.newCanvas(const.resX, const.resY, {msaa = const.msaa})
canvas:setFilter(const.renderFilter, const.renderFilter)

local backgroundElements = {}

function draw.setWindowSize()
    local desktopW, desktopH = love.window.getDesktopDimensions()
    if const.renderScale == "auto" then
        const.renderScale = math.min(desktopW / const.resX, desktopH / const.resY)
    end

    local w, h, flags = love.window.getMode()
    local w, h = const.resX * const.renderScale, const.resY * const.renderScale
    love.window.setMode(w, h, flags)
    love.window.setPosition((desktopW - w)/2, (desktopH - h)/2)
end

local function lerp(a, b, t)
    return (1 - t) * a + t * b
end

local function randf(a, b)
    return lerp(a, b, lm.random())
end

local horizonHeight = 25

local function groundHeightAtDepth(depth)
    return lerp(const.resY, horizonHeight, depth)
end

function draw.initGame()
    -- inspired by this: https://urbanfragment.files.wordpress.com/2012/10/the-sword-of-doom-samurai-cinema.jpg
    for i = 1, 20 do
        local maxDepth = 4
        local zFactor = randf(0.1, 1)
        local w = randf(8, 20) / lerp(1, 4, zFactor)
        table.insert(backgroundElements, {
            _type = "tree",
            x = lm.random(-w, const.resX + w),
            y = groundHeightAtDepth(zFactor),
            z = zFactor,
            width = w,
            color = lerp(0.2, 0.7, zFactor),
        })
    end

    for i = 1, 80 do
        local zFactor = randf(0.1, 1)
        table.insert(backgroundElements, {
            _type = "dust",
            x = lm.random(0, const.resX),
            y = lm.random(0, groundHeightAtDepth(zFactor)),
            z = zFactor,
            color = lerp(0.3, 0.8, zFactor),
        })
    end

    table.sort(backgroundElements, function(a, b)
        return a.z > b.z
    end)
end

local function drawSwordLine(angle, length, color)
    local x, y = math.cos(angle) * length, -math.sin(angle) * length
    lg.setColor(0, 0, 0)
    lg.line(0, 0, x*const.swordHandlePortion, y*const.swordHandlePortion)
    lg.setColor(color)
    lg.line(x*const.swordHandlePortion, y*const.swordHandlePortion, x, y)
end

local function drawSword(player)
    lg.push()
    lg.translate(player.posX, player.posY)
    lg.scale(player.forwardDir, 1)
    lg.translate(unpack(player.sword.offset))
    drawSwordLine(player.sword.angle/180.0*math.pi, player.sword.length, const.swordColors[player.id])
    lg.pop()
end

local function drawBackground(dt)
    local fromY, toY = horizonHeight, const.resY
    lg.setColor(0.7, 0.7, 0.7)
    lg.rectangle("fill", 0, 0, const.resX, horizonHeight)
    for y = fromY, toY do
        local c = lerp(0.6, 0.1, (y - fromY) / (toY - fromY))
        lg.setColor(c, c, c)
        lg.line(0, y, const.resX, y)
    end

    for _, bgElem in ipairs(backgroundElements) do
        lg.setColor(bgElem.color, bgElem.color, bgElem.color)
        if bgElem._type == "tree" then
            lg.rectangle("fill", bgElem.x, 0, bgElem.width, bgElem.y)
        elseif bgElem._type == "dust" then
            local angle = math.pi*0.75 + math.pi*0.1*randf(-1, 1)
            local speed = 2 / lerp(1, 4, bgElem.z)
            local vX, vY = math.cos(angle) * speed, math.sin(angle) * speed
            bgElem.x = bgElem.x + vX * dt
            bgElem.y = bgElem.y + vY * dt
            if bgElem.y > groundHeightAtDepth(bgElem.z) then
                bgElem.x = lm.random(0, const.resX)
                bgElem.y = 0
            end
            lg.rectangle("fill", bgElem.x, bgElem.y, 1, 1)
        end
    end
end

local blinkTimers = {0, 0}

function draw.blinkScore(playerId)
    blinkTimers[playerId] = love.timer.getTime()
end

local function getBlinkColor(playerId)
    local dt = love.timer.getTime() - blinkTimers[playerId]
    local a = 1
    if dt < const.scoreBlinkDuration then
        a = math.cos(dt * math.pi * 2.0 * const.scoreBlinkFrequency) * 0.5 + 0.5
    end
    return {1, 1, 1, a}
end

local time = love.timer.getTime()

function draw.game()
    local dt = love.timer.getTime() - time
    time = love.timer.getTime()

    lg.setCanvas(canvas)
    lg.clear()

    drawBackground(dt)

    for _, player in ipairs(players) do
        if player.visible then
            lg.setColor(player.color)
            local px, py, pw, ph = player:getWorldRect()
            lg.rectangle("fill", px, py, pw, ph)
            drawSword(player)
        end

        if draw.debug then
            local hx, hy, hw, hh = player:getWorldHitbox()
            if hx then
                if player.hitbox._type == "normal" then
                    lg.setColor(0, 0, 1, 0.4)
                else
                    lg.setColor(1, 0, 0, 0.4)
                end
                lg.rectangle("fill", hx, hy, hw, hh)
            end
        end
    end

    particles.update(dt)
    particles.draw()

    lg.setColor(0, 0, 0)
    lg.rectangle("fill", 0, 0, const.resX, const.topBarHeight)
    lg.setColor(players[1].color)
    lg.rectangle("fill", 1, 2, 2, 3)
    lg.setColor(players[2].color)
    lg.rectangle("fill", const.resX - 3, 2, 2, 3)
    lg.setColor(getBlinkColor(1))
    lg.printf(tostring(players[1].score), 4, 1, const.resX - 7)
    lg.setColor(getBlinkColor(2))
    lg.printf(tostring(players[2].score), 4, 1, const.resX - 7, "right")

    lg.setCanvas()

    -- draw to screen
    lg.push()
    lg.setColor(1, 1, 1)
    lg.scale(const.renderScale)
    lg.draw(canvas, 0, 0)
    lg.pop()
end

return draw
