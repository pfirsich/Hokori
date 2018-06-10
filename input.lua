local bit = require("bit")

local const = require("const")
local env = require("environment")
local class = require("util.class")
local FrameDict = require("util.framedict")

local input = {}

input.inputNames = {"up", "down", "left", "right", "action1", "action2"}

function input.keyboardInputReader(mapping)
    return function(input)
        return lk.isDown(mapping[input])
    end
end

local InputState = class("InputState")

function InputState:initialize(inputBuffer, frame, inputIndex)
    self.inputBuffer = inputBuffer
    self.frame = frame
    self.inputIndex = inputIndex
end

-- if pastFrames is given, that input will be checked pastFrames frames in the past
-- (starting to count from the frame before self.frame)
-- i.e. if self.frame is 8 and we pass pastFrames = 5, frames 7, 6, 5, 4, 3 will be checked.

function InputState:checkState(func, pastFrames)
    if pastFrames then
        for frame = self.frame - 1, self.frame - pastFrames, -1 do
            if func(self, frame) then
                return self.frame - frame
            end
        end
        return nil
    else
        return func(self, self.frame) and 0 or nil
    end
end

function InputState:downFunc(frame)
    return self.inputBuffer:getInput(frame, self.inputIndex)
end

function InputState:pressedFunc(frame)
    return self.inputBuffer:getInput(frame, self.inputIndex) and
        not self.inputBuffer:getInput(frame - 1, self.inputIndex)
end

function InputState:releasedFunc(frame)
    return not self.inputBuffer:getInput(frame, self.inputIndex) and
        self.inputBuffer:getInput(frame - 1, self.inputIndex)
end

function InputState:down(pastFrames)
    return self:checkState(InputState.downFunc, pastFrames)
end

function InputState:pressed(pastFrames)
    return self:checkState(InputState.pressedFunc, pastFrames)
end

function InputState:released(pastFrames)
    return self:checkState(InputState.releasedFunc, pastFrames)
end

function InputState:__tostring()
    return ("%s (p: %s, r: %s) - %d, %d, %d"):format(tostring(self:down() ~= nil),
        tostring(self:pressed() ~= nil), tostring(self:released() ~= nil),
        self:down() or -1000, self:pressed() or -1000, self:released() or -1000)
end

local InputBuffer = class("InputBuffer")
input.InputBuffer = InputBuffer

function InputBuffer:initialize(maxNumFrames, inputs, readInputFunc)
    self.inputBuffer = FrameDict(maxNumFrames)

    -- I rely on all data fitting into a single byte for (de)serialization
    assert(#inputs <= 8)
    self.inputs = inputs
    self.readInputFunc = readInputFunc
end

function InputBuffer:setFrame(frame)
    if self.inputBuffer[frame] then
        return self.inputBuffer[frame], false
    else
        self.inputBuffer:set(frame, {})
        return self.inputBuffer[frame], true
    end
end

function InputBuffer:readInput(frame)
    local frameData, addedNewFrame = self:setFrame(frame)
    for i, name in ipairs(self.inputs) do
        frameData[i] = self.readInputFunc(name)
    end
    return addedNewFrame
end

local function packBools(...)
    local firstArg = select(1, ...)
    if type(firstArg) == "table" then
        return packBools(unpack(firstArg))
    end

    local n = select("#", ...)
    local ret = 0
    local power = 1
    for i = 1, n do
        ret = ret + power * (select(i, ...) and 1 or 0)
        power = power * 2
    end
    return ret
end

local function unpackBools(num, value, index)
    index = index or 0
    if index < num then
        return bit.band(value, 2^index) > 0, unpackBools(num, value, index + 1)
    end
end

function InputBuffer:setInput(frame, ...)
    local frameData, addedNewFrame = self:setFrame(frame)
    local arg = select(1, ...)
    if type(arg) == "number" then
        self:setInput(frame, unpackBools(#self.inputs, arg))
    else
        assert(#self.inputs == select("#", ...))
        for i, _ in ipairs(self.inputs) do
            frameData[i] = select(i, ...)
        end
    end
    return addedNewFrame
end

function InputBuffer:getInput(frame, inputIndex)
    return self.inputBuffer[frame] and self.inputBuffer[frame][inputIndex]
end

-- return first missing frame when starting from startFrame
-- startFrame may be greater than endFrame
function InputBuffer:frameMissing(startFrame, endFrame)
    local reverse = startFrame > endFrame
    local step = reverse and -1 or 1
    for frame = startFrame, endFrame, step do
        if not self.inputBuffer[frame] then
            return frame
        end
    end
    return nil
end

function InputBuffer:serialize(numFrames, startFrame)
    startFrame = startFrame or self.inputBuffer:maxFrame()
    local endFrame = startFrame - numFrames + 1
    local firstMissing = self:frameMissing(startFrame, endFrame)
    if firstMissing then
        endFrame = firstMissing + 1
    end
    local str = ""
    for frame = startFrame, endFrame, -1 do
        local char = packBools(self.inputBuffer[frame])
        assert(char < 0xFF)
        str = str .. string.char(char)
    end
    return str
end

function InputBuffer:deserialize(startFrame, str)
    -- TODO: self.inputBuffer:clear()?
    -- iterate in reverse, so add frames at the end of inputBuffer (a lot faster)
    for i = str:len(), 1, -1 do
        self.inputBuffer:set(startFrame - i + 1, {unpackBools(#self.inputs, str:byte(i))})
    end
end

function InputBuffer:getFrame(frame)
    return self.inputBuffer[frame]
end

-- the object retuns by this function is invalidated if *any* function is called on the
-- input buffer, including getState being called again
function InputBuffer:getState(frame, ensureNumFrames)
    if ensureNumFrames then
        assert(self:frameMissing(frame, frame - numFrames + 1))
    end

    if not self.inputBuffer[frame] then
        return nil
    end

    self._inputState = self._inputState or {}
    for inputIndex, inputName in ipairs(self.inputs) do
        self._inputState[inputName] = InputState(self, frame, inputIndex)
    end
    return self._inputState
end

return input
