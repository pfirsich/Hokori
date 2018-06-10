local states = require("player.states.states")

states.Base = require("player.states.base")

local idCounter = 0
local root = "player/states"
for _, file in ipairs(lf.getDirectoryItems(root)) do
    if lf.getInfo(root .. "/" .. file, "file") and file:sub(-4) == ".lua" and
            file ~= "init.lua" and file ~= "states.lua" then
        local state = require("player.states." .. file:sub(1, -5))
        state.id = idCounter
        idCounter = idCounter + 1

        states[state.name] = state
        states[state.id] = state
    end
end

return states
