local function mulList(list, factor)
    local ret = {}
    for i, v in ipairs(list) do
        ret[i] = v * factor
    end
    return ret
end


local const = {
    simFps = 60,
    resX = 96,
    resY = 48,
    renderScale = 10,
    renderFilter = "nearest",
    msaa = 16,
    topBarHeight = 7,

    playerWidth = 8,
    playerHeight = 12,
    playerColors = {
        mulList({0, 1, 0}, 0.6),
        mulList({1, 0.12549, 0.52941}, 0.6),
    },
    levelMinX = 5,
    levelMaxX = 91,

    walkForwardVel = 0.15,
    walkBackwardVel = 0.12,

    dashInputWindow = 8,
    dashFowardVel = 0.8,
    dashBackwardVel = 0.8,
    dashDuration = 12,
    dashCancelAfter = 4,

    tackleVel = 2.0,
    tackleActive = {10, 18},
    tackleHitbox = {"tackle", 0, -10, 7, 8},
    tackleDuration = 18,
    tackleDelay = 8,

    swordLength = 12,
    swordHandlePortion = 0.3,
    swordPositions = {
        normal = {4, -5, 10},
        block = {5, -6, 85},
        blockLow = {5, -4, 80},
        blockHigh = {6, -9, 120},
        strike = {
            startup1 = {7, -11, 160},
            startup2 = {5, -9, 50},
            active = {6, -5, 5},
            recovery = {6, -5, 5},
            --recovery = {4, -4, 0},
        },
        tackle = {-5, -4, -170},
    },

    strikeDuration = 50,
    strikeActive = {12, 15},
    strikeHitbox = {"strike", 0, -10, 19, 8},
    strikeAnimTimes = {
        {"startup1", 0},
        {"startup2", 8},
        {"active", 12},
        {"recovery", 30},
    }
}

return const
