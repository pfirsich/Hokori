local lg = love.graphics

local const = require("const")
local players = require("player")

local draw = {}

lg.setDefaultFilter("nearest", "nearest")
local font = lg.newImageFont("font3x5.png", " 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ.,_!?-:;()+", 1)
lg.setFont(font)

local canvas = lg.newCanvas(const.resX, const.resY, {msaa = const.msaa})
canvas:setFilter(const.renderFilter, const.renderFilter)

local backgroundElements = {}

function draw.setWindowSize()
    local w, h, flags = love.window.getMode()
    love.window.setMode(const.resX * const.renderScale, const.resY * const.renderScale, flags)
end

local function lerp(a, b, t)
    return (1 - t) * a + t * b
end

local horizonHeight = 25

local function groundHeightAtDepth(depth)
    return lerp(const.resY, horizonHeight, depth)
end

function draw.particles(num, x, y, angle, color, lifetime)
    for i = 1, num do

    end
end


function draw.init()
    draw.setWindowSize()

    -- inspired by this: https://urbanfragment.files.wordpress.com/2012/10/the-sword-of-doom-samurai-cinema.jpg
    for i = 1, 20 do
        local maxDepth = 4
        local zFactor = lerp(0.1, 1, lm.random())
        local w = lerp(8, 20, lm.random()) / lerp(1, 4, zFactor)
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
        local zFactor = lerp(0.1, 1, lm.random())
        table.insert(backgroundElements, {
            _type = "leaf",
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
        else
            local angle = math.pi*0.75 + math.pi*0.1*lerp(-1, 1, lm.random())
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

local time = love.timer.getTime()

function love.draw()
    local dt = love.timer.getTime() - time
    time = love.timer.getTime()

    lg.setCanvas(canvas)
    lg.clear()

    drawBackground(dt)

    for _, player in ipairs(players) do
        lg.setColor(player.color)
        if player.state.name == "dash" then
            lg.setColor(1, 1, 1)
        end
        local px, py, pw, ph = player:getWorldRect()
        lg.rectangle("fill", px, py, pw, ph)
        drawSword(player)

        --local hx, hy, hw, hh = player:getWorldHitbox()
        --if hx then
        --    print(hx, hy, hw, hh)
        --    lg.setColor(1, 0, 0, 0.4)
        --    lg.rectangle("fill", hx, hy, hw, hh)
        --end
    end

    lg.setColor(0, 0, 0)
    lg.rectangle("fill", 0, 0, const.resX, const.topBarHeight)
    lg.setColor(1, 1, 1)
    lg.printf(tostring(players[1].score), 1, 1, const.resX - 2)
    lg.printf(tostring(players[2].score), 1, 1, const.resX - 2, "right")

    lg.setCanvas()

    -- draw to screen
    lg.push()
    lg.setColor(1, 1, 1)
    lg.scale(const.renderScale)
    lg.draw(canvas, 0, 0)
    lg.pop()
end

return draw
