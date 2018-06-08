local umath = {}

local abs = math.abs

function umath.aabbIntersect(ax, ay, aw, ah, bx, by, bw, bh)
    return not (bx >= ax + aw or bx + bw <= ax or by >= ay + ah or by + bh <= ay)
end

-- returns mtv for a
-- only call this is there is an intersection
function umath.aabbMtv(ax, ay, aw, ah, bx, by, bw, bh)
    local mtvX, mtvY = 0, 0

    if ax < bx then
        mtvX = bx - (ax + aw)
    else
        mtvX = (bx + bw) - ax
    end

    if ay < by then
        mtvY = by - (ay + ah)
    else
        mtvY = (by + bh) - ay
    end

    if math.abs(mtvX) < math.abs(mtvY) then
       return mtvX, 0
    else
       return 0, mtvY
    end
end

return umath
