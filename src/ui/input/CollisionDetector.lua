local LayoutConfig = require("src.ui.layout.LayoutConfig")

local CollisionDetector = {}
CollisionDetector.__index = CollisionDetector

function CollisionDetector:new()
    local instance = {}
    return setmetatable(instance, self)
end

function CollisionDetector:checkCardCollision(x1, y1, x2, y2)
    return x1 < x2 + LayoutConfig.CARD_WIDTH and
           x1 + LayoutConfig.CARD_WIDTH > x2 and
           y1 < y2 + LayoutConfig.CARD_HEIGHT and
           y1 + LayoutConfig.CARD_HEIGHT > y2
end

function CollisionDetector:findCollisionWithTable(dragX, dragY, tableCards)
    if not tableCards or #tableCards == 0 then return nil, nil end

    local screenWidth = love.graphics.getWidth()
    local totalWidth = #tableCards * LayoutConfig.CARD_WIDTH + (#tableCards - 1) * LayoutConfig.TABLE_CARD_SPACING
    local startX = (screenWidth - totalWidth) / 2
    local startY = LayoutConfig.TABLE_START_Y

    for i, item in ipairs(tableCards) do
        local cardX = startX + (i - 1) * (LayoutConfig.CARD_WIDTH + LayoutConfig.TABLE_CARD_SPACING)
        if self:checkCardCollision(dragX, dragY, cardX, startY) then
            if item.type == "temp_stack" then
                return item, "tempStack"
            else
                return item, "looseCard"
            end
        end
    end
    return nil, nil
end

function CollisionDetector:findTableCardCollision(dragX, dragY, tableCards, excludeIndex)
    if not tableCards or #tableCards == 0 then return nil, nil end

    local screenWidth = love.graphics.getWidth()
    local totalWidth = #tableCards * LayoutConfig.CARD_WIDTH + (#tableCards - 1) * LayoutConfig.TABLE_CARD_SPACING
    local startX = (screenWidth - totalWidth) / 2
    local startY = LayoutConfig.TABLE_START_Y

    for i, item in ipairs(tableCards) do
        if i == excludeIndex then goto continue end

        local cardX = startX + (i - 1) * (LayoutConfig.CARD_WIDTH + LayoutConfig.TABLE_CARD_SPACING)
        if self:checkCardCollision(dragX, dragY, cardX, startY) then
            if item.type == "temp_stack" then
                return item, "tempStack"
            else
                return item, "looseCard"
            end
        end

        ::continue::
    end
    return nil, nil
end

return CollisionDetector