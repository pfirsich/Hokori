local states = require("player.states.states")

states.Base = require("player.states.base")

local root = "player/states"
for _, file in ipairs(lf.getDirectoryItems(root)) do
    if lf.getInfo(root .. "/" .. file, "file") and file:sub(-4) == ".lua" and
            file ~= "init.lua" and file ~= "states.lua" then
        local state = require("player.states." .. file:sub(1, -5))
        states[state.name] = state
    end
end

return states
