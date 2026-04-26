local DragState = {}
DragState.__index = DragState

function DragState:new()
    local instance = {}
    instance.flashTimer = 0
    instance.isDragging = false
    instance.draggingIndex = nil
    instance.dragOffsetX = 0
    instance.dragOffsetY = 0
    instance.isDraggingTableCard = false
    instance.draggingTableCardIndex = nil
    instance.tableCardOffsetX = 0
    instance.tableCardOffsetY = 0
    return setmetatable(instance, self)
end

function DragState:startDrag(index, offsetX, offsetY)
    self.isDragging = true
    self.draggingIndex = index
    self.dragOffsetX = offsetX
    self.dragOffsetY = offsetY
end

function DragState:startTableCardDrag(index, offsetX, offsetY)
    self.isDraggingTableCard = true
    self.draggingTableCardIndex = index
    self.tableCardOffsetX = offsetX
    self.tableCardOffsetY = offsetY
end

function DragState:endDrag()
    self.isDragging = false
    self.draggingIndex = nil
    self.dragOffsetX = 0
    self.dragOffsetY = 0
end

function DragState:endTableCardDrag()
    self.isDraggingTableCard = false
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
    return self.isDragging
end

function DragState:getDraggingIndex()
    return self.draggingIndex
end

function DragState:getDraggingTableCardIndex()
    return self.draggingTableCardIndex
end

return DragState