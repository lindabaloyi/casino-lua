local LayoutConfig = require("src.ui.layout.LayoutConfig")

local PositionCalculator = {}
PositionCalculator.__index = PositionCalculator

function PositionCalculator:new()
    local instance = {}

    instance.handY = nil
    instance.cardPositions = {}
    instance.tableCardPositions = {}

    return setmetatable(instance, self)
end

function PositionCalculator:getDefaultCardPosition(index, numCards)
    local screenWidth = love.graphics.getWidth()
    local handWidth = LayoutConfig.CARD_WIDTH + (numCards - 1) * (LayoutConfig.CARD_WIDTH - LayoutConfig.CARD_OVERLAP)
    local baseX = (screenWidth - handWidth) / 2
    local cardX = baseX + (index - 1) * (LayoutConfig.CARD_WIDTH - LayoutConfig.CARD_OVERLAP)
    local cardY = self.handY + LayoutConfig.CARD_OFFSET_Y
    return { x = cardX, y = cardY }
end

function PositionCalculator:getDefaultTableCardPosition(index, tableCards)
    local screenWidth = love.graphics.getWidth()
    local totalWidth = #tableCards * LayoutConfig.CARD_WIDTH + (#tableCards - 1) * LayoutConfig.TABLE_CARD_SPACING
    local startX = (screenWidth - totalWidth) / 2
    local startY = LayoutConfig.TABLE_START_Y
    local cardX = startX + (index - 1) * (LayoutConfig.CARD_WIDTH + LayoutConfig.TABLE_CARD_SPACING)
    return { x = cardX, y = startY }
end

function PositionCalculator:setHandY(handY)
    self.handY = handY
end

function PositionCalculator:getCardPositions()
    return self.cardPositions
end

function PositionCalculator:setCardPosition(index, x, y)
    self.cardPositions[index] = { x = x, y = y }
end

function PositionCalculator:getTableCardPositions()
    return self.tableCardPositions
end

function PositionCalculator:setTableCardPosition(index, x, y)
    self.tableCardPositions[index] = { x = x, y = y }
end

function PositionCalculator:recalculateHandPositions(numCards)
    self.cardPositions = {}
    for i = 1, numCards do
        self.cardPositions[i] = self:getDefaultCardPosition(i, numCards)
    end
end

function PositionCalculator:recalculateTablePositions(tableCards)
    self.tableCardPositions = {}
    for i = 1, #tableCards do
        self.tableCardPositions[i] = self:getDefaultTableCardPosition(i, tableCards)
    end
end

function PositionCalculator:clearPositions()
    self.cardPositions = {}
    self.tableCardPositions = {}
end

function PositionCalculator:getCardPosition(index)
    return self.cardPositions[index]
end

function PositionCalculator:getTableCardPosition(index)
    return self.tableCardPositions[index]
end

return PositionCalculator