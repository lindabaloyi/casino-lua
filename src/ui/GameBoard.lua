local LayoutConfig = require("src.ui.layout.LayoutConfig")
local PositionCalculator = require("src.ui.layout.PositionCalculator")
local DragState = require("src.ui.drag.DragState")
local HitDetector = require("src.ui.input.HitDetector")
local CollisionDetector = require("src.ui.input.CollisionDetector")
local InputHandler = require("src.ui.input.InputHandler")
local BoardRenderer = require("src.ui.render.BoardRenderer")

local GameBoard = {}
GameBoard.__index = GameBoard

function GameBoard:load()
    self.positionCalculator = PositionCalculator:new()
    self.positionCalculator:setHandY(LayoutConfig.HAND_Y)

    self.dragState = DragState:new()

    self.collisionDetector = CollisionDetector:new()

    self.hitDetector = HitDetector:new(self.positionCalculator)

    self.inputHandler = InputHandler:new(
        self.dragState,
        self.positionCalculator,
        self.hitDetector,
        self.collisionDetector
    )

    self.renderer = BoardRenderer:new(LayoutConfig.HAND_Y)
end

function GameBoard:update(dt, gameState, mouseX, mouseY)
    self.dragState:update(dt)
    self.inputHandler:updatePositions()
end

function GameBoard:draw(gameState, mouseX, mouseY)
    self.renderer:drawFlash(self.dragState:getFlashTimer())
    self.renderer:drawTableArea()
    self.renderer:drawTableCards(
        gameState.tableCards,
        self.positionCalculator,
        self.dragState:getDraggingTableCardIndex()
    )
    self.renderer:drawHandArea(
        gameState.playerHand,
        self.positionCalculator,
        self.dragState:getDraggingIndex()
    )
end

function GameBoard:mousepressed(x, y, button, sm)
    self.inputHandler:handleMousePressed(x, y, button, sm.gameState)
end

function GameBoard:mousedragged(x, y, dx, dy)
end

function GameBoard:mousereleased(x, y, button, sm)
    self.inputHandler:handleMouseReleased(x, y, button, sm.gameState)
end

function GameBoard:mousemove(x, y)
end

return GameBoard