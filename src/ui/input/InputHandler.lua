local LayoutConfig = require("src.ui.layout.LayoutConfig")
local Trail = require("src.shared.actions.trail")
local CreateTemp = require("src.shared.actions.createTemp")
local Capture = require("src.shared.actions.capture")
local CaptureOwn = require("src.shared.actions.captureOwn")
local AcceptTemp = require("src.shared.actions.acceptTemp")

local InputHandler = {}
InputHandler.__index = InputHandler

function InputHandler:new(dragState, positionCalculator, hitDetector, collisionDetector, boardRenderer)
    local instance = {}
    instance.dragState = dragState
    instance.positionCalculator = positionCalculator
    instance.hitDetector = hitDetector
    instance.collisionDetector = collisionDetector
    instance.boardRenderer = boardRenderer
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
    if self.dragState:isDragging() and self.dragState:getDraggingIndex() then
        local hand = gameState.playerHand
        local card = hand[self.dragState:getDraggingIndex()]
        local draggedPos = self.positionCalculator:getCardPosition(self.dragState:getDraggingIndex())

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
            elseif targetType == "buildStack" then
                local success, msg = CaptureOwn.execute(gameState, {card = card, target = target}, 0)
                if success then
                    log("[captureOwn] " .. msg)
                else
                    log("[captureOwn] Failed: " .. msg)
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
                local idx = self.dragState:getDraggingIndex()
                local defaultPos = self.positionCalculator:getDefaultCardPosition(idx, #hand)
                self.positionCalculator:setCardPosition(idx, defaultPos.x, defaultPos.y)
            else
                self.positionCalculator:clearPositions()
                self.positionCalculator:recalculateHandPositions(#gameState.playerHand)
            end
        else
            local idx = self.dragState:getDraggingIndex()
            local defaultPos = self.positionCalculator:getDefaultCardPosition(idx, #hand)
            self.positionCalculator:setCardPosition(idx, defaultPos.x, defaultPos.y)
        end
    end

    if self.dragState:isDraggingTableCard() and self.dragState:getDraggingTableCardIndex() then
        local tableCards = gameState.tableCards
        local draggedCard = tableCards[self.dragState:getDraggingTableCardIndex()]
        local draggedPos = self.positionCalculator:getTableCardPosition(self.dragState:getDraggingTableCardIndex())

        if draggedCard and draggedPos then
            local actionFailed = false

            log("[TableCard] draggedPos: " .. math.floor(draggedPos.x) .. "," .. math.floor(draggedPos.y))

            local target, targetType = self.collisionDetector:findTableCardCollision(
                draggedPos.x, draggedPos.y, tableCards, self.dragState:getDraggingTableCardIndex())

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
                local idx = self.dragState:getDraggingTableCardIndex()
                local defaultPos = self.positionCalculator:getDefaultTableCardPosition(idx, tableCards)
                self.positionCalculator:setTableCardPosition(idx, defaultPos.x, defaultPos.y)
            else
                self.positionCalculator:clearPositions()
            end
        end

        self.dragState:endTableCardDrag()
    end

    self.dragState:endDrag()
end

function InputHandler:handleDrag(x, y)
    if self.dragState:isDragging() then
        local idx = self.dragState:getDraggingIndex()
        if idx then
            self.positionCalculator:setCardPosition(
                idx,
                x - self.dragState:getDragOffsetX(),
                y - self.dragState:getDragOffsetY()
            )
        end
    end

    if self.dragState:isDraggingTableCard() then
        local idx = self.dragState:getDraggingTableCardIndex()
        if idx then
            self.positionCalculator:setTableCardPosition(
                idx,
                x - self.dragState:getTableCardOffsetX(),
                y - self.dragState:getTableCardOffsetY()
            )
        end
    end
end

function InputHandler:handleAcceptButtonClick(x, y, gameState)
    -- Check if clicked on any Accept button
    if self.boardRenderer then
        local acceptButtons = self.boardRenderer.acceptButtons
        if acceptButtons then
            for stackIndex, btn in pairs(acceptButtons) do
                if x >= btn.x and x <= btn.x + btn.w and
                   y >= btn.y and y <= btn.y + btn.h then
                    log("[AcceptTemp] Clicked Accept button for stack at index: " .. stackIndex)

                    -- Execute accept temp
                    local success, msg = AcceptTemp.execute(gameState, { stackIndex = stackIndex }, 0)
                    if success then
                        log("[AcceptTemp] Success: " .. msg)
                        return true
                    else
                        log("[AcceptTemp] Failed: " .. msg)
                        return false, msg
                    end
                end
            end
        end
    end
    return false
end

return InputHandler