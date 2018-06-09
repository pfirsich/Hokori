local umath = {}

local abs = math.abs

function umath.aabbIntersect(ax, ay, aw, ah, bx, by, bw, bh)
    return not (bx >= ax + aw or bx + bw <= ax or by >= ay + ah or by + bh <= ay)
end

function umath.lerp(a, b, t)
    return (1 - t) * a + t * b
end

function umath.randf(a, b)
    return umath.lerp(a, b, lm.random())
end

function umath.deg2rad(deg)
    return deg / 180.0 * math.pi
end

-- if you want to multiply a number in a loop, you have to adjust that multiplication
-- for delta time too.
-- Addition is simpler (just multiply with dt), for multiplication you have to use this
function umath.dtMultiply(factor, dt)
    return math.exp(math.log(factor) * dt)
end

function umath.mulList(list, factor)
    local ret = {}
    for i, v in ipairs(list) do
        ret[i] = v * factor
    end
    return ret
end

return umath
