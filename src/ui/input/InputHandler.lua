local LayoutConfig = require("src.ui.layout.LayoutConfig")
local Trail = require("src.shared.actions.trail")
local CreateTemp = require("src.shared.actions.createTemp")
local Capture = require("src.shared.actions.capture")

local InputHandler = {}
InputHandler.__index = InputHandler

function InputHandler:new(dragState, positionCalculator, hitDetector, collisionDetector)
    local instance = {}
    instance.dragState = dragState
    instance.positionCalculator = positionCalculator
    instance.hitDetector = hitDetector
    instance.collisionDetector = collisionDetector
    return setmetatable(instance, self)
end

function InputHandler:handleMousePressed(x, y, button, gameState)
    self.dragState:triggerFlash()

    local tableHitIndex = self.hitDetector:getTableCardAtPosition(x, y, gameState.tableCards)
    if tableHitIndex then
        local item = gameState.tableCards[tableHitIndex]
        if item and not item.type then
            log("[HIT] TableCard:" .. tableHitIndex)
            local defaultPos = self.positionCalculator:getDefaultTableCardPosition(tableHitIndex, gameState.tableCards)
            local offsetX = x - defaultPos.x
            local offsetY = y - defaultPos.y
            self.dragState:startTableCardDrag(tableHitIndex, offsetX, offsetY)
            self.positionCalculator:setTableCardPosition(tableHitIndex, x - offsetX, y - offsetY)
            return
        end
    end

    local hitIndex = self.hitDetector:getCardAtPosition(x, y, gameState.playerHand)

    if hitIndex then
        log("[HIT] Card:" .. hitIndex)
        local defaultPos = self.positionCalculator:getDefaultCardPosition(hitIndex, #gameState.playerHand)
        local currentPos = self.positionCalculator:getCardPosition(hitIndex) or defaultPos
        local offsetX = x - currentPos.x
        local offsetY = y - currentPos.y
        self.dragState:startDrag(hitIndex, offsetX, offsetY)
        self.positionCalculator:setCardPosition(hitIndex, x - offsetX, y - offsetY)
    else
        self.dragState:endDrag()
    end
end

function InputHandler:handleMouseReleased(x, y, button, gameState)
    if self.dragState.isDragging and self.dragState.draggingIndex then
        local hand = gameState.playerHand
        local card = hand[self.dragState.draggingIndex]
        local draggedPos = self.positionCalculator:getCardPosition(self.dragState.draggingIndex)

        if card and y >= 0 and y <= LayoutConfig.TABLE_AREA_HEIGHT then
            local actionFailed = false

            log("[Collision] draggedPos: " .. math.floor(draggedPos.x) .. "," .. math.floor(draggedPos.y))

            local target, targetType = self.collisionDetector:findCollisionWithTable(draggedPos.x, draggedPos.y, gameState.tableCards)

            log("[Collision] result: " .. tostring(targetType) .. " -> " .. tostring(target))

            if targetType == "tempStack" then
                local success, msg = Capture.execute(gameState, target, 0)
                if success then
                    log("[Capture] " .. msg)
                else
                    log("[Capture] Failed: " .. msg)
                    actionFailed = true
                end
            elseif targetType == "looseCard" then
                local success, msg = CreateTemp.execute(gameState, {card = card, target = target, source = 'hand'}, 0)
                if success then
                    log("[CreateTemp] " .. msg)
                else
                    log("[CreateTemp] Failed: " .. msg)
                    actionFailed = true
                end
            else
                local success, msg = Trail.execute(gameState, card)
                if success then
                    log("[Trail] " .. msg)
                else
                    log("[Trail] Failed: " .. msg)
                    actionFailed = true
                end
            end

            if actionFailed then
                self.positionCalculator:setCardPosition(
                    self.dragState.draggingIndex,
                    self.positionCalculator:getDefaultCardPosition(self.dragState.draggingIndex, #hand).x,
                    self.positionCalculator:getDefaultCardPosition(self.dragState.draggingIndex, #hand).y
                )
            else
                self.positionCalculator:clearPositions()
                self.positionCalculator:recalculateHandPositions(#gameState.playerHand)
            end
        else
            self.positionCalculator:setCardPosition(
                self.dragState.draggingIndex,
                self.positionCalculator:getDefaultCardPosition(self.dragState.draggingIndex, #hand).x,
                self.positionCalculator:getDefaultCardPosition(self.dragState.draggingIndex, #hand).y
            )
        end
    end

    if self.dragState.isDraggingTableCard and self.dragState.draggingTableCardIndex then
        local tableCards = gameState.tableCards
        local draggedCard = tableCards[self.dragState.draggingTableCardIndex]
        local draggedPos = self.positionCalculator:getTableCardPosition(self.dragState.draggingTableCardIndex)

        if draggedCard and draggedPos then
            local actionFailed = false

            log("[TableCard] draggedPos: " .. math.floor(draggedPos.x) .. "," .. math.floor(draggedPos.y))

            local target, targetType = self.collisionDetector:findTableCardCollision(
                draggedPos.x, draggedPos.y, tableCards, self.dragState.draggingTableCardIndex)

            log("[TableCard] result: " .. tostring(targetType) .. " -> " .. tostring(target))

            if targetType == "tempStack" then
                log("[TableCard] Add to temp - not implemented")
                actionFailed = true
            elseif targetType == "looseCard" then
                local success, msg = CreateTemp.execute(gameState, {card = draggedCard, target = target, source = 'table'}, 0)
                if success then
                    log("[CreateTemp] " .. msg)
                else
                    log("[CreateTemp] Failed: " .. msg)
                    actionFailed = true
                end
            else
                log("[TableCard] No collision - snap back")
                actionFailed = true
            end

            if actionFailed then
                self.positionCalculator:setTableCardPosition(
                    self.dragState.draggingTableCardIndex,
                    self.positionCalculator:getDefaultTableCardPosition(self.dragState.draggingTableCardIndex, tableCards).x,
                    self.positionCalculator:getDefaultTableCardPosition(self.dragState.draggingTableCardIndex, tableCards).y
                )
            else
                self.positionCalculator:clearPositions()
            end
        end

        self.dragState:endTableCardDrag()
    end

    self.dragState:endDrag()
end

function InputHandler:updatePositions()
    local mx, my = love.mouse.getPosition()

    if self.dragState.isDragging and self.dragState.draggingIndex and mx and my then
        self.positionCalculator:setCardPosition(
            self.dragState.draggingIndex,
            mx - self.dragState.dragOffsetX,
            my - self.dragState.dragOffsetY
        )
    end

    if self.dragState.isDraggingTableCard and self.dragState.draggingTableCardIndex and mx and my then
        self.positionCalculator:setTableCardPosition(
            self.dragState.draggingTableCardIndex,
            mx - self.dragState.tableCardOffsetX,
            my - self.dragState.tableCardOffsetY
        )
    end
end

return InputHandler