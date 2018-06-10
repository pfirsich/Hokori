local scenes = require("scenes")
local draw = require("draw")
local sounds = require("sounds")
local const = require("const")

local scene = {name = "mainmenu"}

local items = {
    {"LOCAL MULTIPLAYER", "enterGame", 1},
    --{"MATCHMAKING", "matchmaking"},
    {"HOST PRIVATE GAME", "hostGame"},
    {"CONNECT", "joinGame"},
}
local selectedItem = 1

function scene.enter()
end

function scene.update()
end

function scene.draw()
    draw.start()
    draw.menuBase()

    local y = 14
    for i, item in ipairs(items) do
        local text = item[1]
        lg.setColor(0.6, 0.6, 0.6)
        if i == selectedItem then
            lg.setColor(1, 1, 1)
            text = " " .. text
        end
        lg.print(text, 5, y)
        y = y + 8
    end
    draw.finalize()
end

function scene.keypressed(key)
    if key == "up" or key == "w" then
        selectedItem = selectedItem - 1
        if selectedItem < 1 then
            selectedItem = #items
        end
        sounds.menu:play()
    elseif key == "down" or key == "s" then
        selectedItem = selectedItem + 1
        if selectedItem > #items then
            selectedItem = 1
        end
        sounds.menu:play()
    elseif key == "return" or key == "f" then
        local item = items[selectedItem]
        scenes.enter(scenes[item[2]], select(3, unpack(item)))
        sounds.menu:play()
    end
end

function scene.exit()
end

return scene
