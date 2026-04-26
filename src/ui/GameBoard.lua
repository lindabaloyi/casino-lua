local Button = require("src.ui.Button")
local Finder = require("src.shared.registry.Finder")
local Trail = require("src.shared.actions.trail")
local CreateTemp = require("src.shared.actions.createTemp")
local Capture = require("src.shared.actions.capture")

local GameBoard = {}
GameBoard.__index = GameBoard

local CARD_WIDTH = 60
local CARD_HEIGHT = 90
local CARD_OVERLAP = 18
local HAND_Y = 280
local CARD_OFFSET_Y = 60
local TABLE_AREA_HEIGHT = 355

function GameBoard:load()
    self.flashTimer = 0
    self.draggingIndex = nil
    self.dragOffsetX = 0
    self.dragOffsetY = 0
    self.cardPositions = {}
    self.handY = HAND_Y
    self.isDragging = false
    
    Finder.register("looseCard", function(x, y, tableCards)
        return self:findLooseCardAtPosition(x, y, tableCards)
    end)
    
    Finder.register("tempStack", function(x, y, tableCards)
        return self:findTempStackAtPosition(x, y, tableCards)
    end)
end

function GameBoard:update(dt, gameState, mouseX, mouseY)
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
end

function GameBoard:draw(gameState, mouseX, mouseY)
    if self.flashTimer > 0 then
        love.graphics.setColor(1, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1)
    end

    self:drawTableArea()
    self:drawTableCards(gameState)
    self:drawHandArea(gameState.playerHand)
end

function GameBoard:mousepressed(x, y, button, sm)
    self.flashTimer = 0.3
    
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

function GameBoard:mousedragged(x, y, dx, dy)
    -- Handled in update() via love.mouse.getPosition()
end

function GameBoard:mousereleased(x, y, button, sm)
    log("[mousereleased]")
    
    if self.isDragging and self.draggingIndex then
        local hand = sm.gameState.playerHand
        local card = hand[self.draggingIndex]
        
        if card and y >= 0 and y <= TABLE_AREA_HEIGHT then
            local actionFailed = false
            
            -- Check for temp stack first (priority)
            local tempStack = Finder.find("tempStack", x, y, sm.gameState.tableCards)
            if tempStack then
                local success, msg = Capture.execute(sm.gameState, tempStack, 0)
                if success then
                    log("[Capture] " .. msg)
                else
                    log("[Capture] Failed: " .. msg)
                    actionFailed = true
                end
            else
                -- Check for loose card
                local looseCard = Finder.find("looseCard", x, y, sm.gameState.tableCards)
                if looseCard then
                    local success, msg = CreateTemp.execute(sm.gameState, {card = card, target = looseCard}, 0)
                    if success then
                        log("[CreateTemp] " .. msg)
                    else
                        log("[CreateTemp] Failed: " .. msg)
                        actionFailed = true
                    end
                else
                    -- Trail the card
                    local success, msg = Trail.execute(sm.gameState, card)
                    if success then
                        log("[Trail] " .. msg)
                    else
                        log("[Trail] Failed: " .. msg)
                        actionFailed = true
                    end
                end
            end
            
            if actionFailed then
                -- Snap back on failure
                self.cardPositions[self.draggingIndex] = self:getDefaultCardPosition(self.draggingIndex, #hand)
            else
                -- Rebuild card positions on success
                self.cardPositions = {}
                local newHandSize = #sm.gameState.playerHand
                for i = 1, newHandSize do
                    self.cardPositions[i] = self:getDefaultCardPosition(i, newHandSize)
                end
            end
        else
            -- Not on table → snap back
            self.cardPositions[self.draggingIndex] = self:getDefaultCardPosition(self.draggingIndex, #hand)
        end
    end
    
    self.isDragging = false
    self.draggingIndex = nil
end

function GameBoard:mousemove(x, y)
    -- Handled in update() via love.mouse.getPosition()
end

function GameBoard:findLooseCardAtPosition(x, y, tableCards)
    if not tableCards or #tableCards == 0 then return nil end
    
    for i, item in ipairs(tableCards) do
        if not item.type then
            local cardX = 50 + (i - 1) * (CARD_WIDTH + 10)
            local cardY = 50
            if x >= cardX and x <= cardX + CARD_WIDTH and y >= cardY and y <= cardY + CARD_HEIGHT then
                return item
            end
        end
    end
    return nil
end

function GameBoard:findTempStackAtPosition(x, y, tableCards)
    if not tableCards or #tableCards == 0 then return nil end
    
    for i, item in ipairs(tableCards) do
        if item.type == "temp_stack" then
            local cardX = 50 + (i - 1) * (CARD_WIDTH + 10)
            local cardY = 50
            if x >= cardX and x <= cardX + CARD_WIDTH and y >= cardY and y <= cardY + CARD_HEIGHT then
                return item
            end
        end
    end
    return nil
end

function GameBoard:getDefaultCardPosition(index, numCards)
    local screenWidth = love.graphics.getWidth()
    local handWidth = CARD_WIDTH + (numCards - 1) * (CARD_WIDTH - CARD_OVERLAP)
    local baseX = (screenWidth - handWidth) / 2
    local cardX = baseX + (index - 1) * (CARD_WIDTH - CARD_OVERLAP)
    local cardY = self.handY + CARD_OFFSET_Y
    return { x = cardX, y = cardY }
end

function GameBoard:getCardAtPosition(mx, my, hand)
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

function GameBoard:drawTableArea()
    local screenWidth = love.graphics.getWidth()
    love.graphics.setColor(46/255, 125/255, 50/255)
    love.graphics.rectangle("fill", 0, 0, screenWidth, 355)
end

function GameBoard:drawTempStack(stack, x, y)
    local overlap = CARD_WIDTH * 0.3

    love.graphics.setColor(1, 1, 1)
    stack.cards[1]:draw(x, y, CARD_WIDTH, CARD_HEIGHT)
    stack.cards[2]:draw(x + overlap, y - overlap, CARD_WIDTH, CARD_HEIGHT)

    local badgeX = x + CARD_WIDTH - 15
    local badgeY = y + CARD_HEIGHT - 15
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.circle("fill", badgeX, badgeY, 14)
    love.graphics.setColor(1, 1, 0)
    love.graphics.setFont(love.graphics.newFont(12))
    love.graphics.print(tostring(stack.value), badgeX - 6, badgeY - 6)
end

function GameBoard:drawTableCards(gameState)
    local tableCards = gameState.tableCards
    if not tableCards or #tableCards == 0 then
        return
    end

    local screenWidth = love.graphics.getWidth()
    local totalWidth = #tableCards * CARD_WIDTH + (#tableCards - 1) * 10
    local startX = (screenWidth - totalWidth) / 2
    local startY = 50

    for i, item in ipairs(tableCards) do
        local x = startX + (i - 1) * (CARD_WIDTH + 10)
        
        if item.type == "temp_stack" then
            self:drawTempStack(item, x, startY)
        else
            item:draw(x, startY, CARD_WIDTH, CARD_HEIGHT)
        end
    end
end

function GameBoard:drawHandArea(hand)
    -- Draw background for hand area covering the full card height
    love.graphics.setColor(46/255, 125/255, 50/255)
    local screenWidth = love.graphics.getWidth()
    love.graphics.rectangle("fill", 0, self.handY, screenWidth, CARD_OFFSET_Y + CARD_HEIGHT)
    
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

return GameBoard