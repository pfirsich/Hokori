local input = require("input")
local const = require("const")
local env = require("environment")

local menuInput = {}

function menuInput.anyDown(inputName)
    local set = const.controlSets[env.CONTROL_SET]
    return lk.isDown(set[1][inputName]) and lk.isDown(set[2][inputName])
end

function menuInput.isPlayerInput(key, inputName)
    local set = const.controlSets[env.CONTROL_SET]
    return set[1][inputName] == key or set[2][inputName] == key
end

return menuInput
