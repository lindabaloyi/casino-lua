local LayoutConfig = require("src.ui.layout.LayoutConfig")

local BoardRenderer = {}
BoardRenderer.__index = BoardRenderer

function BoardRenderer:new(handY)
    local instance = {}
    instance.handY = handY or LayoutConfig.HAND_Y
    instance.acceptButtons = {}  -- Track accept button positions for click detection
    return setmetatable(instance, self)
end

function BoardRenderer:getAcceptButtonPosition(index)
    return self.acceptButtons[index]
end

function BoardRenderer:drawAcceptButton(x, y, index)
    local btnW, btnH = 50, 20
    local btnX = x + (LayoutConfig.CARD_WIDTH - btnW) / 2
    local btnY = y + LayoutConfig.CARD_HEIGHT + 5

    -- Store position for click detection
    self.acceptButtons[index] = {
        x = btnX,
        y = btnY,
        w = btnW,
        h = btnH
    }

    -- Draw button
    local mx, my = love.mouse.getPosition()
    local isHovered = mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH

    love.graphics.setColor(isHovered and {0.3, 0.7, 0.3} or {0.2, 0.5, 0.2})
    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", btnX, btnY, btnW, btnH)

    love.graphics.setFont(love.graphics.newFont(10))
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Accept", btnX + 8, btnY + 5)
end

function BoardRenderer:clearAcceptButtons()
    self.acceptButtons = {}
end

function BoardRenderer:drawTableArea()
    local screenWidth = love.graphics.getWidth()
    love.graphics.setColor(46/255, 125/255, 50/255)
    love.graphics.rectangle("fill", 0, 0, screenWidth, LayoutConfig.TABLE_AREA_HEIGHT)
end

function BoardRenderer:drawTempStack(stack, x, y)
    if not stack.cards or #stack.cards == 0 then
        return
    end

    love.graphics.setColor(1, 1, 1)
    if stack.cards[1] then
        stack.cards[1]:draw(x, y, LayoutConfig.CARD_WIDTH, LayoutConfig.CARD_HEIGHT)
    end
    if stack.cards[2] then
        stack.cards[2]:draw(x, y, LayoutConfig.CARD_WIDTH, LayoutConfig.CARD_HEIGHT)
    end

    local badgeX = x + LayoutConfig.CARD_WIDTH - 15
    local badgeY = y + LayoutConfig.CARD_HEIGHT - 15
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.circle("fill", badgeX, badgeY, 14)
    love.graphics.setColor(1, 1, 0)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print(tostring(stack.value), badgeX - 6, badgeY - 6)
end

function BoardRenderer:drawTableCards(tableCards, positionCalculator, draggingTableCardIndex, currentPlayerIndex)
    if not tableCards or #tableCards == 0 then
        return
    end

    self:clearAcceptButtons()

    local screenWidth = love.graphics.getWidth()
    local totalWidth = #tableCards * LayoutConfig.CARD_WIDTH + (#tableCards - 1) * LayoutConfig.TABLE_CARD_SPACING
    local startX = (screenWidth - totalWidth) / 2
    local startY = LayoutConfig.TABLE_START_Y

    for i, item in ipairs(tableCards) do
        if not item then goto continue end
        if i ~= draggingTableCardIndex then
            local x = startX + (i - 1) * (LayoutConfig.CARD_WIDTH + LayoutConfig.TABLE_CARD_SPACING)

            if item.type == "temp_stack" then
                self:drawTempStack(item, x, startY)
                -- Draw Accept button for player's temp stacks
                if item.owner == currentPlayerIndex then
                    self:drawAcceptButton(x, startY, i)
                end
            elseif item.type == "build_stack" then
                self:drawTempStack(item, x, startY)
            else
                item:draw(x, startY, LayoutConfig.CARD_WIDTH, LayoutConfig.CARD_HEIGHT)
            end
        end
        ::continue::
    end

    if draggingTableCardIndex and tableCards[draggingTableCardIndex] then
        local item = tableCards[draggingTableCardIndex]
        if item then
            local pos = positionCalculator:getTableCardPosition(draggingTableCardIndex)
            if pos then
                if item.type == "temp_stack" then
                    self:drawTempStack(item, pos.x, pos.y)
                elseif item.type == "build_stack" then
                    self:drawTempStack(item, pos.x, pos.y)
                else
                    item:draw(pos.x, pos.y, LayoutConfig.CARD_WIDTH, LayoutConfig.CARD_HEIGHT)
                end
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

function BoardRenderer:drawCapturePiles(playerCaptures, opponentCaptures)
    local scaledWidth = LayoutConfig.CARD_WIDTH * LayoutConfig.CAPTURE_CARD_SCALE
    local scaledHeight = LayoutConfig.CARD_HEIGHT * LayoutConfig.CAPTURE_CARD_SCALE

    love.graphics.setFont(love.graphics.newFont(12))

    if opponentCaptures and #opponentCaptures > 0 then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Dealer (" .. #opponentCaptures .. ")", LayoutConfig.CAPTURE_PILE_LEFT_X, LayoutConfig.CAPTURE_PILE_Y - 15)

        local startX = LayoutConfig.CAPTURE_PILE_LEFT_X
        local maxCards = math.min(#opponentCaptures, LayoutConfig.CAPTURE_PILE_MAX_SHOWN)

        for i = 1, maxCards do
            local card = opponentCaptures[i]
            local x = startX + (i - 1) * LayoutConfig.CAPTURE_CARD_OFFSET_X
            local y = LayoutConfig.CAPTURE_PILE_Y
            card:draw(x, y, scaledWidth, scaledHeight)
        end
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("Dealer (0)", LayoutConfig.CAPTURE_PILE_LEFT_X, LayoutConfig.CAPTURE_PILE_Y - 15)
    end

    if playerCaptures and #playerCaptures > 0 then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("You (" .. #playerCaptures .. ")", LayoutConfig.CAPTURE_PILE_RIGHT_X, LayoutConfig.CAPTURE_PILE_Y - 15)

        local maxCards = math.min(#playerCaptures, LayoutConfig.CAPTURE_PILE_MAX_SHOWN)

        for i = 1, maxCards do
            local card = playerCaptures[i]
            local x = LayoutConfig.CAPTURE_PILE_RIGHT_X + (i - 1) * LayoutConfig.CAPTURE_CARD_OFFSET_X
            local y = LayoutConfig.CAPTURE_PILE_Y
            card:draw(x, y, scaledWidth, scaledHeight)
        end
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("You (0)", LayoutConfig.CAPTURE_PILE_RIGHT_X, LayoutConfig.CAPTURE_PILE_Y - 15)
    end

    love.graphics.setColor(1, 1, 1)
end

return BoardRenderer