local Button = require("src.ui.Button")

local GameScreen = {}
GameScreen.__index = GameScreen

local CARD_WIDTH = 60
local CARD_HEIGHT = 90
local CARD_OVERLAP = 18

function GameScreen:load()
    self.backButton = Button:new(270, 250, 100, 40, "BACK")
end

function GameScreen:update(dt, gameState, mouseX, mouseY)
end

function GameScreen:draw(gameState, mouseX, mouseY)
    self:drawHandArea(gameState.dealerHand, 20)
    self:drawHandArea(gameState.playerHand, 250)
    
    self.backButton:draw(
        mouseX,
        mouseY,
        {255/255, 215/255, 0/255, 255},
        {100/255, 100/255, 100/255, 255},
        {218/255, 165/255, 32/255, 255}
    )
end

function GameScreen:mousepressed(x, y, button, screenManager)
    if self.backButton:clicked(x, y) then
        screenManager:switch("home")
    end
end

function GameScreen:mousemove(x, y)
end

function GameScreen:drawHandArea(hand, startY)
    love.graphics.setColor(46/255, 125/255, 50/255)
    love.graphics.rectangle("fill", 0, startY, 640, 100)
    
    local numCards = #hand
    if numCards == 0 then return end
    
    local handWidth = CARD_WIDTH + (numCards - 1) * (CARD_WIDTH - CARD_OVERLAP)
    local x = (640 - handWidth) / 2
    
    for i, card in ipairs(hand) do
        local cardX = x + (i - 1) * (CARD_WIDTH - CARD_OVERLAP)
        card:draw(cardX, startY + 5, CARD_WIDTH, CARD_HEIGHT)
    end
end

return GameScreen