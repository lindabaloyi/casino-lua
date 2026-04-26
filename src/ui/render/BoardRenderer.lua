local LayoutConfig = require("src.ui.layout.LayoutConfig")

local BoardRenderer = {}
BoardRenderer.__index = BoardRenderer

function BoardRenderer:new(handY)
    local instance = {}
    instance.handY = handY or LayoutConfig.HAND_Y
    return setmetatable(instance, self)
end

function BoardRenderer:drawTableArea()
    local screenWidth = love.graphics.getWidth()
    love.graphics.setColor(46/255, 125/255, 50/255)
    love.graphics.rectangle("fill", 0, 0, screenWidth, LayoutConfig.TABLE_AREA_HEIGHT)
end

function BoardRenderer:drawTempStack(stack, x, y)
    love.graphics.setColor(1, 1, 1)
    stack.cards[1]:draw(x, y, LayoutConfig.CARD_WIDTH, LayoutConfig.CARD_HEIGHT)
    stack.cards[2]:draw(x, y, LayoutConfig.CARD_WIDTH, LayoutConfig.CARD_HEIGHT)

    local badgeX = x + LayoutConfig.CARD_WIDTH - 15
    local badgeY = y + LayoutConfig.CARD_HEIGHT - 15
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.circle("fill", badgeX, badgeY, 14)
    love.graphics.setColor(1, 1, 0)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print(tostring(stack.value), badgeX - 6, badgeY - 6)
end

function BoardRenderer:drawTableCards(tableCards, positionCalculator, draggingTableCardIndex)
    if not tableCards or #tableCards == 0 then
        return
    end

    local screenWidth = love.graphics.getWidth()
    local totalWidth = #tableCards * LayoutConfig.CARD_WIDTH + (#tableCards - 1) * LayoutConfig.TABLE_CARD_SPACING
    local startX = (screenWidth - totalWidth) / 2
    local startY = LayoutConfig.TABLE_START_Y

    for i, item in ipairs(tableCards) do
        if i ~= draggingTableCardIndex then
            local x = startX + (i - 1) * (LayoutConfig.CARD_WIDTH + LayoutConfig.TABLE_CARD_SPACING)

            if item.type == "temp_stack" then
                self:drawTempStack(item, x, startY)
            else
                item:draw(x, startY, LayoutConfig.CARD_WIDTH, LayoutConfig.CARD_HEIGHT)
            end
        end
    end

    if draggingTableCardIndex and tableCards[draggingTableCardIndex] then
        local item = tableCards[draggingTableCardIndex]
        local pos = positionCalculator:getTableCardPosition(draggingTableCardIndex)
        if pos then
            if item.type == "temp_stack" then
                self:drawTempStack(item, pos.x, pos.y)
            else
                item:draw(pos.x, pos.y, LayoutConfig.CARD_WIDTH, LayoutConfig.CARD_HEIGHT)
            end
        end
    end
end

function BoardRenderer:drawHandArea(hand, positionCalculator, draggingIndex)
    love.graphics.setColor(46/255, 125/255, 50/255)
    local screenWidth = love.graphics.getWidth()
    love.graphics.rectangle("fill", 0, self.handY, screenWidth, LayoutConfig.CARD_OFFSET_Y + LayoutConfig.CARD_HEIGHT)

    local numCards = #hand
    if numCards == 0 then return end

    for i, card in ipairs(hand) do
        if i ~= draggingIndex then
            local pos = positionCalculator:getCardPositions()[i] or positionCalculator:getDefaultCardPosition(i, numCards)
            card:draw(pos.x, pos.y, LayoutConfig.CARD_WIDTH, LayoutConfig.CARD_HEIGHT)
        end
    end

    if draggingIndex and hand[draggingIndex] then
        local pos = positionCalculator:getCardPosition(draggingIndex)
        if pos then
            hand[draggingIndex]:draw(pos.x, pos.y, LayoutConfig.CARD_WIDTH, LayoutConfig.CARD_HEIGHT)
        end
    end
end

function BoardRenderer:drawFlash(flashTimer)
    if flashTimer > 0 then
        love.graphics.setColor(1, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1)
    end
end

return BoardRenderer