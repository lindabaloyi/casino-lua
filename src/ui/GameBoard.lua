local json = require("dkjson")
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

    self.renderer = BoardRenderer:new(LayoutConfig.HAND_Y)

    -- Pass renderer to input handler for accept button detection
    self.inputHandler = InputHandler:new(
        self.dragState,
        self.positionCalculator,
        self.hitDetector,
        self.collisionDetector,
        self.renderer
    )

    self.currentPlayerIndex = 0  -- Player 0 (human player)

    -- Multiplayer state
    self.multiplayer = false
    self.network = nil
    self.roomId = nil
    self.playerIndex = 0
end

function GameBoard:startMultiplayer(roomId, playerIndex, network)
    self.multiplayer = true
    self.roomId = roomId
    self.playerIndex = playerIndex
    self.network = network
    log("Started multiplayer: room " .. roomId .. ", player " .. playerIndex)
end

function GameBoard:update(dt, gameState, mouseX, mouseY)
    self.dragState:update(dt)

    if self.dragState:isDragging() or self.dragState:isDraggingTableCard() then
        local mx, my = love.mouse.getPosition()
        if mx and my then
            self.inputHandler:handleDrag(mx, my)
        end
    end

    if self.multiplayer and self.network then
        self.network:update()
        local msg = self.network:getNextMessage()
        while msg do
            log("GameBoard received: " .. json.encode(msg))

            if msg.type == "chat" then
                log("Player " .. msg.playerId .. " says: " .. msg.message)
            end

            msg = self.network:getNextMessage()
        end
    end
end

function GameBoard:draw(gameState, mouseX, mouseY)
    self.renderer:drawFlash(self.dragState:getFlashTimer())
    self.renderer:drawTableArea()
    self.renderer:drawCapturePiles(
        gameState.players[1].captures,
        gameState.players[2].captures
    )
    self.renderer:drawTableCards(
        gameState.tableCards,
        self.positionCalculator,
        self.dragState:getDraggingTableCardIndex(),
        self.currentPlayerIndex
    )
    self.renderer:drawHandArea(
        gameState.playerHand,
        self.positionCalculator,
        self.dragState:getDraggingIndex()
    )
end

function GameBoard:mousepressed(x, y, button, sm)
    -- First check if clicked on an Accept button
    local accepted, err = self.inputHandler:handleAcceptButtonClick(x, y, sm.gameState)
    if accepted then
        return
    end

    -- Otherwise, handle normal card interaction
    self.inputHandler:handleMousePressed(x, y, button, sm.gameState)
end

function GameBoard:mousedragged(x, y, dx, dy)
    self.inputHandler:handleDrag(x, y)
end

function GameBoard:mousereleased(x, y, button, sm)
    self.inputHandler:handleMouseReleased(x, y, button, sm.gameState)
end

function GameBoard:mousemove(x, y)
    if self.dragState:isDragging() or self.dragState:isDraggingTableCard() then
        self.inputHandler:handleDrag(x, y)
    end
end

return GameBoard