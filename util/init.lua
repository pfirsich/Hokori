-- misalleneous stuff

local util = {}

function util.dotString(maxLen)
    local ret = ""
    local dotCount = math.floor(love.timer.getTime() % (maxLen or 3) + 1)
    for i = 1, dotCount do
        ret = ret .. "."
    end
    return ret
end

return util
