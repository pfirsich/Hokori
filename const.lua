local umath = require("util.math")

local const = {
    simFps = 60,
    resX = 96,
    resY = 48,
    renderScale = "auto",
    renderFilter = "nearest",
    msaa = 16,

    horizonHeight = 25,
    treeCount = 20,
    dustCount = 80,
    minZ = 0.1,
    treeColRange = {0.2, 0.7},
    dustColRange = {0.3, 0.8},
    treeWidthRange = {8, 20},
    treeMaxDepth = 4,
    skyColor = {0.7, 0.7, 0.7},
    groundColRange = {0.6, 0.1},
    dustMoveAngle = 135,
    dustAngleDelta = 18,
    dustFrontSpeed = 2,
    dustMaxDepth = 4,

    hitboxColors = {
        default = {1, 1, 0, 0.4},
        normal = {0, 0, 1, 0.4},
    },

    topBarHeight = 7,
    colorIconEdgeSpacing = 1,
    colorIconWidth = 2,
    colorIconHeight = 3,
    scoreIconSpacing = 1,

    controlSets = {
        keyboard = {
            {
                up = "w", down = "s", left = "a", right = "d",
                action1 = "f", action2 = "g"
            },
            {
                up = "up", down = "down", left = "left", right = "right",
                action1 = "end", action2 = "pagedown"
            },
        },
        stab = {
            {
                up = "pagedown", down = "f11", left = "end", right = "f12",
                action1 = "f10", action2 = "8"
            },
            {
                up = "9", down = "1", left = "0", right = "7",
                action1 = "3", action2 = "4"
            },
        },
    },


    playerWidth = 8,
    playerHeight = 12,
    playerColors = {
        umath.mulList({0, 1, 0}, 0.6),
        umath.mulList({1, 0.12549, 0.52941}, 0.6),
    },
    levelMinX = 5,
    levelMaxX = 91,

    spawnEdgeDistance = 20,

    attackBufferFrames = 7,

    walkForwardVel = 0.24,
    walkBackwardVel = 0.18,
    normalHitbox = {"normal", -5, -10, 15, 8},

    dashInputWindow = 10,
    dashFowardVel = 1.0,
    dashBackwardVel = 1.0,
    dashDuration = 12,
    dashCancelAfter = 4,

    tackleVel = 2,
    tackleActive = {9, 15},
    tackleHitbox = {"tackle", 0, -10, 7, 8},
    tackleDuration = 20,
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
    swordColors = {
        {0.92, 1.0, 0.92},
        {1.0, 0.92, 0.92},
    },

    strikeDuration = 50,
    strikeActive = {12, 15},
    strikeHitbox = {"strike", 0, -10, 18, 8},
    strikeAnimTimes = {
        {"startup1", 0},
        {"startup2", 8},
        {"active", 12},
        {"recovery", 30},
    },

    deathFreezeDuration = 20,
    deathDuration = 160,

    scoreBlinkDuration = 3.0,
    scoreBlinkFrequency = 3.0,

    blockParticleNum = 50,

    helpOverlayAlpha = 0.8,
    helpOffsetY = 7,
    helpText = {
        {1, 1, 1}, "DOUBLE TAP TO DASH\n",
        {1, 1, 1}, "HOLD BACK TO ", {0, 0, 1}, "BLOCK\n\n",
        {1, 0, 0}, "STRIKE", {0.8, 0.8, 0.8}, " BEATS ", {0, 1, 0}, "TACKLE\n",
        {0, 1, 0}, "TACKLE", {0.8, 0.8, 0.8}, " BEATS ", {0, 0, 1}, "BLOCK\n",
        {0, 0, 1}, "BLOCK", {0.8, 0.8, 0.8}, " BEATS ", {1, 0, 0}, "STRIKE\n",
    },

    menuOverlayAlpha = 0.5,
    musicVolume = 0.04,

    defaultPort = 4574,
    -- this is pretty much the low end of the maximum acceptable ping
    defaultRtt = 120,
    minInputDelay = 2,
    inputBufferLength = 40, -- frames
    maxSavedPlayerStates = 40,
    numNetUpdateInputFrames = 15,
}

return const
