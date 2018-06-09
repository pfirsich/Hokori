local const = require("const")

local input = {}

local inputNames = {"up", "down", "left", "right", "action1", "action2"}

-- inputs are in the order of inputNames
local controlSets = {
    keyboard = {
        {"w", "s", "a", "d", "f", "g"},
        {"up", "down", "left", "right", "end", "pagedown"},
    },
    stab = {
        {"pagedown", "f11", "end", "f12", "f10", "8"},
        {"9", "1", "0", "7", "3", "4"},
    },
    gamepad = {
        gamepad = true,
        "dpup", "dpdown", "dpleft", "dpright", "a", "b",
    }
}

local controlSet = controlSets.keyboard

local function inputStateFunction(player, inputIndex)
    if controlSet.gamepad then
        local joystick = love.joystick.getJoysticks()[player]
        return function()
            return joystick:isGamepadDown(controlSet[inputIndex])
        end
    else
        return function()
            return lk.isDown(controlSet[player][inputIndex])
        end
    end
end

input.controllers = {}

local maxHistory = const.simFps

local function getHistory(self, index)
    if #self.history == 0 then return nil end
    while index > #self.history do
        index = index - #self.history
    end
    while index < 1 do
        index = #self.history + index
    end
    return self.history[index]
end

local function inputInHistory(self, field, time)
    local start = self.nextHistoryIndex - 1
    for i = start, start - time, -1 do
        if field == "state" and getHistory(self, i) then
            return i
        end
        if field == "pressed" and getHistory(self, i) and not getHistory(self, i-1) then
            return i
        end
        if field == "released" and not getHistory(self, i) and getHistory(self, i-1) then
            return i
        end
    end
    return nil
end

local function updateController(self)
    for _, inputName in ipairs(inputNames) do
        local inputState = self[inputName]
        -- push old state to history
        inputState.history[inputState.nextHistoryIndex] = inputState.state
        inputState.nextHistoryIndex = inputState.nextHistoryIndex + 1
        if inputState.nextHistoryIndex > maxHistory then
            inputState.nextHistoryIndex = 1
        end

        -- update state
        inputState.lastState = inputState.state
        inputState.state = inputState.stateFunc()
        inputState.pressed = inputState.state and not inputState.lastState
        inputState.released = not inputState.state and inputState.lastState
    end
end

for player = 1, 2 do
    local ctrl = {}
    for inputIndex = 1, 6 do
        ctrl[inputNames[inputIndex]] = {
            stateFunc = inputStateFunction(player, inputIndex),
            lastState = false,
            state = false,
            pressed = false,
            released = false,
            history = {},
            nextHistoryIndex = 1,
            inHistory = inputInHistory,
        }
    end
    input.controllers[player] = ctrl
end

input.dummyController = {}
for inputIndex = 1, 6 do
    local inputState = {
        stateFunc = function() return false end,
        lastState = false,
        state = false,
        pressed = false,
        released = false,
        history = {},
        nextHistoryIndex = maxHistory,
        inHistory = inputInHistory,
    }
    for i = 1, maxHistory do
        inputState.history[i] = false
    end
    input.dummyController[inputNames[inputIndex]] = inputState
end

function input.update()
    for i = 1, 2 do
        updateController(input.controllers[i])
    end
end

return input
