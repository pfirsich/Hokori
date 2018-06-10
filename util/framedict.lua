local class = require("util.class")

local FrameDict = class("FrameDict")

-- This is a table with integer keys that holds a maximum of maxNumFrames entries.
-- If another entry is added, the entry with the smallest index is removed.

-- It is used to save data for frames (the frame is the index), willing filling up RAM quickly
-- (e.g. player states, input data)

-- this whole thing seems very inefficient

function FrameDict:initialize(maxNumFrames)
    self.maxNumFrames = maxNumFrames
    -- a sorted list of all the saved indices
    self.savedFrames = {}
end

local function insertSorted(list, value)
    for i = #list, 1, -1 do
        if value > list[i] then
            table.insert(list, i+1, value)
            return
        end
    end
    table.insert(list, 1, value)
end

function FrameDict:set(frame, value)
    if value == nil then
        for i, f in ipairs(self.savedFrames) do
            if f == frame then
                table.remove(self.savedFrames, i)
                break
            end
        end
    else
        if not self[frame] then
            insertSorted(self.savedFrames, frame)
            if #self.savedFrames > self.maxNumFrames then
                local minFrame = self.savedFrames[1]
                self[minFrame] = nil
                table.remove(self.savedFrames, 1)
            end
        end
    end
    self[frame] = value
end

function FrameDict:clear()
    for _, frame in ipairs(self.savedFrames) do
        self[frame] = nil
    end
    self.savedFrames = {}
end

function FrameDict:minFrame()
    return self.savedFrames[1]
end

function FrameDict:maxFrame()
    return self.savedFrames[#self.savedFrames]
end

return FrameDict
