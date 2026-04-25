local Button = require("src.ui.Button")

local GameScreen = {}
GameScreen.__index = GameScreen

local CARD_WIDTH = 60
local CARD_HEIGHT = 90
local CARD_OVERLAP = 18

function GameScreen:load()
end

function GameScreen:update(dt, gameState, mouseX, mouseY)
end

function GameScreen:draw(gameState, mouseX, mouseY)
    self:drawHandArea(gameState.playerHand, 250)
end

function GameScreen:mousepressed(x, y, button, screenManager)
end

function GameScreen:mousemove(x, y)
end

function GameScreen:drawHandArea(hand, startY)
    love.graphics.setColor(46/255, 125/255, 50/255)
    local screenWidth = love.graphics.getWidth()
    love.graphics.rectangle("fill", 0, startY, screenWidth, 100)
    
    local numCards = #hand
    if numCards == 0 then return end
    
    local handWidth = CARD_WIDTH + (numCards - 1) * (CARD_WIDTH - CARD_OVERLAP)
    local x = (screenWidth - handWidth) / 2
    
    for i, card in ipairs(hand) do
        local cardX = x + (i - 1) * (CARD_WIDTH - CARD_OVERLAP)
        card:draw(cardX, startY + 5, CARD_WIDTH, CARD_HEIGHT)
    end
end

return GameScreen