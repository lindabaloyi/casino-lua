local Button = require("src.ui.Button")

local GameScreen = {}
GameScreen.__index = GameScreen

local CARD_WIDTH = 60
local CARD_HEIGHT = 90
local CARD_OVERLAP = 18
local HAND_Y = 280
local CARD_OFFSET_Y = 60

local SQUARE_SIZE = 50

function GameScreen:load()
    self.flashTimer = 0
    self.draggingIndex = nil
    self.dragOffsetX = 0
    self.dragOffsetY = 0
    self.cardPositions = {}
    self.handY = HAND_Y
    self.isDragging = false
    
    self.square = {
        x = 423,
        y = 152,
        size = SQUARE_SIZE,
        color = {0, 0, 0}
    }
    self.squareDragging = false
    self.squareOffsetX = 0
    self.squareOffsetY = 0
end

function GameScreen:update(dt, gameState, mouseX, mouseY)
    if self.flashTimer > 0 then
        self.flashTimer = self.flashTimer - dt
    end
    
    local mx, my = love.mouse.getPosition()
    
    if self.isDragging and self.draggingIndex and mx and my then
        self.cardPositions[self.draggingIndex] = {
            x = mx - self.dragOffsetX,
            y = my - self.dragOffsetY
        }
    end
    
    if self.squareDragging and mx and my then
        self.square.x = mx - self.squareOffsetX
        self.square.y = my - self.squareOffsetY
    end
end

function GameScreen:draw(gameState, mouseX, mouseY)
    if self.flashTimer > 0 then
        love.graphics.setColor(1, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1)
    end
    
    self:drawTableArea()
    self:drawSquare()
    self:drawHandArea(gameState.playerHand)
    
    love.graphics.setColor(1, 1, 0)
    love.graphics.setNewFont(12)
    love.graphics.print("Square: " .. tostring(self.squareDragging), 10, 10)
    love.graphics.print("Square Pos: " .. tostring(self.square.x) .. "," .. tostring(self.square.y), 10, 25)
end

function GameScreen:mousepressed(x, y, button, sm)
    log("[mousepressed] " .. x .. "," .. y)
    log("Square bounds:" .. self.square.x .. "," .. self.square.y)
    log("Mouse in square?" .. tostring(x >= self.square.x and x <= self.square.x + self.square.size and y >= self.square.y and y <= self.square.y + self.square.size))
    
    self.flashTimer = 0.3
    
    if x >= self.square.x and x <= self.square.x + self.square.size and
       y >= self.square.y and y <= self.square.y + self.square.size then
        log("[HIT] Square")
        self.squareDragging = true
        self.squareOffsetX = x - self.square.x
        self.squareOffsetY = y - self.square.y
        return
    end
    
    -- Check cards
    local hand = sm.gameState.playerHand
    local hitIndex = self:getCardAtPosition(x, y, hand)
    
    if hitIndex then
        log("[HIT] Card:" .. hitIndex)
        self.isDragging = true
        self.draggingIndex = hitIndex

        local defaultPos = self:getDefaultCardPosition(hitIndex, #hand)
        local currentPos = self.cardPositions[hitIndex] or defaultPos
        self.dragOffsetX = x - currentPos.x
        self.dragOffsetY = y - currentPos.y

        -- Set initial dragged position (same as currentPos, but ensures entry)
        self.cardPositions[hitIndex] = {
            x = x - self.dragOffsetX,
            y = y - self.dragOffsetY
        }
    else
        -- Click on empty area: ensure no accidental dragging
        self.isDragging = false
        self.draggingIndex = nil
    end
end

function GameScreen:mousedragged(x, y, dx, dy)
    log("[mousedragged] " .. x .. "," .. y .. " isDragging:" .. tostring(self.isDragging) .. " draggingIndex:" .. tostring(self.draggingIndex))
    
    -- Move card if dragging
    if self.isDragging and self.draggingIndex then
        self.cardPositions[self.draggingIndex] = {
            x = x - self.dragOffsetX,
            y = y - self.dragOffsetY
        }
    end

    -- Move square if dragging
    if self.squareDragging then
        self.square.x = x - self.squareOffsetX
        self.square.y = y - self.squareOffsetY
    end
end

function GameScreen:mousereleased(x, y, button, sm)
    log("[mousereleased]")
    self.flashTimer = 0.1
    
    -- Snap card back to default position in hand
    if self.draggingIndex then
        local hand = sm.gameState.playerHand
        self.cardPositions[self.draggingIndex] = self:getDefaultCardPosition(self.draggingIndex, #hand)
    end
    
    -- Reset all dragging flags
    self.isDragging = false
    self.draggingIndex = nil
    self.squareDragging = false
end

function GameScreen:mousemove(x, y)
    log("[mousemove] " .. x .. "," .. y .. " isDragging:" .. tostring(self.isDragging))
    
    if self.isDragging and self.draggingIndex then
        self.cardPositions[self.draggingIndex] = {
            x = x - self.dragOffsetX,
            y = y - self.dragOffsetY
        }
    end
    
    if self.squareDragging then
        self.square.x = x - self.squareOffsetX
        self.square.y = y - self.squareOffsetY
    end
end

function GameScreen:drawSquare()
    love.graphics.setColor(self.square.color[1], self.square.color[2], self.square.color[3])
    love.graphics.rectangle("fill", self.square.x, self.square.y, self.square.size, self.square.size)
end

function GameScreen:getDefaultCardPosition(index, numCards)
    local screenWidth = love.graphics.getWidth()
    local handWidth = CARD_WIDTH + (numCards - 1) * (CARD_WIDTH - CARD_OVERLAP)
    local baseX = (screenWidth - handWidth) / 2
    local cardX = baseX + (index - 1) * (CARD_WIDTH - CARD_OVERLAP)
    local cardY = self.handY + CARD_OFFSET_Y
    return { x = cardX, y = cardY }
end

function GameScreen:getCardAtPosition(mx, my, hand)
    local numCards = #hand
    if numCards == 0 then return nil end
    
    -- Check from top (last card) to bottom (first card) for proper overlap
    for i = numCards, 1, -1 do
        local pos = self.cardPositions[i] or self:getDefaultCardPosition(i, numCards)
        if mx >= pos.x and mx <= pos.x + CARD_WIDTH and
           my >= pos.y and my <= pos.y + CARD_HEIGHT then
            return i
        end
    end
    return nil
end

function GameScreen:drawTableArea()
    local screenWidth = love.graphics.getWidth()
    love.graphics.setColor(46/255, 125/255, 50/255)
    love.graphics.rectangle("fill", 0, 0, screenWidth, 355)
end

function GameScreen:drawHandArea(hand)
    -- Draw background for hand area
    love.graphics.setColor(46/255, 125/255, 50/255)
    local screenWidth = love.graphics.getWidth()
    love.graphics.rectangle("fill", 0, self.handY, screenWidth, 60)
    
    local numCards = #hand
    if numCards == 0 then return end
    
    -- Draw all non-dragging cards
    for i, card in ipairs(hand) do
        if i ~= self.draggingIndex then
            local pos = self.cardPositions[i] or self:getDefaultCardPosition(i, numCards)
            card:draw(pos.x, pos.y, CARD_WIDTH, CARD_HEIGHT)
        end
    end
    
    -- Draw the dragged card last (on top)
    if self.draggingIndex and hand[self.draggingIndex] then
        local pos = self.cardPositions[self.draggingIndex]
        if pos then
            hand[self.draggingIndex]:draw(pos.x, pos.y, CARD_WIDTH, CARD_HEIGHT)
        end
    end
end

return GameScreen