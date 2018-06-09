local const = require("const")
local players = require("player")
local particles = require("particles")
local umath = require("util.math")

local draw = {}

draw.debug = false

lg.setDefaultFilter("nearest", "nearest")
local font = lg.newImageFont("media/font3x5.png", " 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ.,_!?-:;()+", 1)
lg.setFont(font)

local canvas = lg.newCanvas(const.resX, const.resY, {msaa = const.msaa})
canvas:setFilter(const.renderFilter, const.renderFilter)

local backgroundElements = {}

local blinkTimers = {0, 0}

local time = love.timer.getTime()

local lerp = umath.lerp
local randf = umath.randf
local deg2rad = umath.deg2rad

local function groundHeightAtDepth(depth)
    return lerp(const.resY, const.horizonHeight, depth)
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
    lg.setColor(const.skyColor)
    lg.rectangle("fill", 0, 0, const.resX, const.horizonHeight)

    local fromY, toY = const.horizonHeight, const.resY
    for y = fromY, toY do
        local c = lerp(const.groundColRange[1], const.groundColRange[2],
            (y - fromY) / (toY - fromY))
        lg.setColor(c, c, c)
        lg.line(0, y, const.resX, y)
    end

    for _, bgElem in ipairs(backgroundElements) do
        lg.setColor(bgElem.color, bgElem.color, bgElem.color)
        if bgElem._type == "tree" then
            lg.rectangle("fill", bgElem.x, 0, bgElem.width, bgElem.y)
        elseif bgElem._type == "dust" then
            -- update dust
            local angle = deg2rad(const.dustMoveAngle) + deg2rad(const.dustAngleDelta)*randf(-1, 1)
            local speed = const.dustFrontSpeed / lerp(1, const.dustMaxDepth, bgElem.z)
            local vX, vY = math.cos(angle) * speed, math.sin(angle) * speed
            bgElem.x = bgElem.x + vX * dt
            bgElem.y = bgElem.y + vY * dt
            if bgElem.y > groundHeightAtDepth(bgElem.z) then
                bgElem.x = lm.random(0, const.resX)
                bgElem.y = 0
            end
            -- draw
            lg.rectangle("fill", bgElem.x, bgElem.y, 1, 1)
        end
    end
end

local function getScoreBlinkColor(playerId)
    local dt = love.timer.getTime() - blinkTimers[playerId]
    local a = 1
    if dt < const.scoreBlinkDuration then
        a = math.cos(dt * math.pi * 2.0 * const.scoreBlinkFrequency) * 0.5 + 0.5
    end
    return {1, 1, 1, a}
end


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

function draw.initGame()
    -- inspired by this: https://urbanfragment.files.wordpress.com/2012/10/the-sword-of-doom-samurai-cinema.jpg
    for i = 1, const.treeCount do
        local zFactor = randf(const.minZ, 1)
        local w = randf(const.treeWidthRange[1], const.treeWidthRange[2]) /
            lerp(1, const.treeMaxDepth, zFactor)
        table.insert(backgroundElements, {
            _type = "tree",
            x = lm.random(-w, const.resX + w),
            y = groundHeightAtDepth(zFactor),
            z = zFactor,
            width = w,
            color = lerp(const.treeColRange[1], const.treeColRange[2], zFactor),
        })
    end

    for i = 1, const.dustCount do
        local zFactor = randf(const.minZ, 1)
        table.insert(backgroundElements, {
            _type = "dust",
            x = lm.random(0, const.resX),
            y = lm.random(0, groundHeightAtDepth(zFactor)),
            z = zFactor,
            color = lerp(const.dustColRange[1], const.dustColRange[2], zFactor),
        })
    end

    table.sort(backgroundElements, function(a, b)
        return a.z > b.z
    end)
end

function draw.blinkScore(playerId)
    blinkTimers[playerId] = love.timer.getTime()
end

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
                local color = const.hitboxColors[player.hitbox._type] or const.hitboxColors.default
                lg.setColor(color)
                lg.rectangle("fill", hx, hy, hw, hh)
            end
        end
    end

    particles.updateAndDraw(dt)

    lg.setColor(0, 0, 0)
    lg.rectangle("fill", 0, 0, const.resX, const.topBarHeight)

    lg.setColor(players[1].color)
    local xPadding = const.colorIconEdgeSpacing
    local yPadding = (const.topBarHeight - const.colorIconHeight) / 2
    lg.rectangle("fill", xPadding, yPadding, const.colorIconWidth, const.colorIconHeight)
    lg.setColor(players[2].color)
    lg.rectangle("fill", const.resX - xPadding - const.colorIconWidth, yPadding,
        const.colorIconWidth, const.colorIconHeight)

    local scoreFromX = xPadding + const.colorIconWidth + const.scoreIconSpacing
    -- + 1 because we are not counting the first pixel of the range?
    local scoreToX = const.resX - scoreFromX - xPadding -
        const.colorIconWidth - const.scoreIconSpacing + 1
    lg.setColor(getScoreBlinkColor(1))
    lg.printf(tostring(players[1].score), scoreFromX, 1, scoreToX)
    lg.setColor(getScoreBlinkColor(2))
    lg.printf(tostring(players[2].score), scoreFromX, 1, scoreToX, "right")

    lg.setCanvas()

    -- draw to screen
    lg.push()
    lg.setColor(1, 1, 1)
    lg.scale(const.renderScale)
    lg.draw(canvas, 0, 0)
    lg.pop()
end

return draw
