local class = require("util.class")
local sounds = require("sounds")
local const = require("const")
local menuInput = require("util.menuinput")

local Menu = class("Menu")

function Menu:initialize(items, startItemIndex)
    self.items = items
    self.selectedItem = startItemIndex or 1
end

function Menu:draw(xOffset, yOffset)
    local itemPadding = 3
    local itemSpacing = 5 + itemPadding
    local y = yOffset
    if not y then
        y = math.floor((const.resY - #self.items * itemSpacing) / 2.0 + itemPadding / 2 + 0.5)
    end
    for i, item in ipairs(self.items) do
        local text = item.title
        lg.setColor(0.6, 0.6, 0.6)
        if i == self.selectedItem then
            lg.setColor(1, 1, 1)
            text = " " .. text
        end
        lg.print(text, xOffset or 5, y)
        y = y + itemSpacing
    end
end

function Menu:prev()
    self.selectedItem = self.selectedItem - 1
    if self.selectedItem < 1 then
        self.selectedItem = #self.items
    end
    sounds.menu:play()
end

function Menu:next()
    self.selectedItem = self.selectedItem + 1
    if self.selectedItem > #self.items then
        self.selectedItem = 1
    end
    sounds.menu:play()
end

function Menu:choose()
    local item = self.items[self.selectedItem]
    if item and item.func then
        sounds.menu:play()
        item.func(item)
    end
end

function Menu:keypressed(key)
    if menuInput.isPlayerInput(key, "up") then
        self:prev()
    elseif menuInput.isPlayerInput(key, "down") then
        self:next()
    elseif menuInput.isPlayerInput(key, "action1") or key == "return" then
        self:choose()
    end
end

return Menu
