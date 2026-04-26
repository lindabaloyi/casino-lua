local LayoutConfig = require("src.ui.layout.LayoutConfig")

local HitDetector = {}
HitDetector.__index = HitDetector

function HitDetector:new(positionCalculator)
    local instance = {}
    instance.positionCalculator = positionCalculator
    return setmetatable(instance, self)
end

function HitDetector:getTableCardAtPosition(mx, my, tableCards)
    if not tableCards or #tableCards == 0 then return nil end

    local screenWidth = love.graphics.getWidth()
    local totalWidth = #tableCards * LayoutConfig.CARD_WIDTH + (#tableCards - 1) * LayoutConfig.TABLE_CARD_SPACING
    local startX = (screenWidth - totalWidth) / 2
    local startY = LayoutConfig.TABLE_START_Y

    for i, item in ipairs(tableCards) do
        local cardX = startX + (i - 1) * (LayoutConfig.CARD_WIDTH + LayoutConfig.TABLE_CARD_SPACING)
        if mx >= cardX and mx <= cardX + LayoutConfig.CARD_WIDTH and my >= startY and my <= startY + LayoutConfig.CARD_HEIGHT then
            return i
        end
    end
    return nil
end

function HitDetector:getCardAtPosition(mx, my, hand)
    local numCards = #hand
    if numCards == 0 then return nil end

    for i = numCards, 1, -1 do
        local pos = self.positionCalculator:getCardPositions()[i] or self.positionCalculator:getDefaultCardPosition(i, numCards)
        if mx >= pos.x and mx <= pos.x + LayoutConfig.CARD_WIDTH and
           my >= pos.y and my <= pos.y + LayoutConfig.CARD_HEIGHT then
            return i
        end
    end
    return nil
end

function HitDetector:findLooseCardAtPosition(x, y, tableCards)
    if not tableCards or #tableCards == 0 then return nil end

    local screenWidth = love.graphics.getWidth()
    local totalWidth = #tableCards * LayoutConfig.CARD_WIDTH + (#tableCards - 1) * LayoutConfig.TABLE_CARD_SPACING
    local startX = (screenWidth - totalWidth) / 2
    local startY = LayoutConfig.TABLE_START_Y

    for i, item in ipairs(tableCards) do
        if not item.type then
            local cardX = startX + (i - 1) * (LayoutConfig.CARD_WIDTH + LayoutConfig.TABLE_CARD_SPACING)
            if x >= cardX and x <= cardX + LayoutConfig.CARD_WIDTH and y >= startY and y <= startY + LayoutConfig.CARD_HEIGHT then
                return item
            end
        end
    end
    return nil
end

function HitDetector:findTempStackAtPosition(x, y, tableCards)
    if not tableCards or #tableCards == 0 then return nil end

    local screenWidth = love.graphics.getWidth()
    local totalWidth = #tableCards * LayoutConfig.CARD_WIDTH + (#tableCards - 1) * LayoutConfig.TABLE_CARD_SPACING
    local startX = (screenWidth - totalWidth) / 2
    local startY = LayoutConfig.TABLE_START_Y

    for i, item in ipairs(tableCards) do
        if item.type == "temp_stack" then
            local cardX = startX + (i - 1) * (LayoutConfig.CARD_WIDTH + LayoutConfig.TABLE_CARD_SPACING)
            if x >= cardX and x <= cardX + LayoutConfig.CARD_WIDTH and y >= startY and y <= startY + LayoutConfig.CARD_HEIGHT then
                return item
            end
        end
    end
    return nil
end

return HitDetector