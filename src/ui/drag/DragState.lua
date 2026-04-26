local DragState = {}
DragState.__index = DragState

function DragState:new()
    local instance = {}
    instance.flashTimer = 0
    instance.dragging = false
    instance.draggingIndex = nil
    instance.dragOffsetX = 0
    instance.dragOffsetY = 0
    instance.draggingTableCard = false
    instance.draggingTableCardIndex = nil
    instance.tableCardOffsetX = 0
    instance.tableCardOffsetY = 0
    return setmetatable(instance, self)
end

function DragState:startDrag(index, offsetX, offsetY)
    self.dragging = true
    self.draggingIndex = index
    self.dragOffsetX = offsetX
    self.dragOffsetY = offsetY
end

function DragState:startTableCardDrag(index, offsetX, offsetY)
    self.draggingTableCard = true
    self.draggingTableCardIndex = index
    self.tableCardOffsetX = offsetX
    self.tableCardOffsetY = offsetY
end

function DragState:endDrag()
    self.dragging = false
    self.draggingIndex = nil
    self.dragOffsetX = 0
    self.dragOffsetY = 0
end

function DragState:endTableCardDrag()
    self.draggingTableCard = false
    self.draggingTableCardIndex = nil
    self.tableCardOffsetX = 0
    self.tableCardOffsetY = 0
end

function DragState:triggerFlash()
    self.flashTimer = 0.3
end

function DragState:update(dt)
    if self.flashTimer > 0 then
        self.flashTimer = self.flashTimer - dt
    end
end

function DragState:isFlashing()
    return self.flashTimer > 0
end

function DragState:getFlashTimer()
    return self.flashTimer
end

function DragState:isDragging()
    return self.dragging
end

function DragState:getDraggingIndex()
    return self.draggingIndex
end

function DragState:getDraggingTableCardIndex()
    return self.draggingTableCardIndex
end

function DragState:isDraggingTableCard()
    return self.draggingTableCard
end

function DragState:getDragOffsetX()
    return self.dragOffsetX
end

function DragState:getDragOffsetY()
    return self.dragOffsetY
end

function DragState:getTableCardOffsetX()
    return self.tableCardOffsetX
end

function DragState:getTableCardOffsetY()
    return self.tableCardOffsetY
end

return DragState