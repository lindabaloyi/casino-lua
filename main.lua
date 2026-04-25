local Card = require("src.Card")
local Deck = require("src.Deck")

local currentScreen = "home"
local deck = nil
local playerHand = {}
local dealerHand = {}
local mouseX, mouseY = 0, 0

local CARD_WIDTH = 60
local CARD_HEIGHT = 90
local CARD_OVERLAP = 18

local playButton = { x = 270, y = 150, w = 100, h = 40 }
local backButton = { x = 270, y = 250, w = 100, h = 40 }

function love.load()
    love.window.setTitle("Casino")
    love.window.setMode(640, 360, {
        resizable = false,
        fullscreen = false
    })
    
    math.randomseed(os.time())
end

function love.update(dt)
end

function love.draw()
    love.graphics.setBackgroundColor(26/255, 26/255, 46/255)
    love.graphics.clear()
    
    if currentScreen == "home" then
        drawHome()
    elseif currentScreen == "game" then
        drawGame()
    end
end

function love.mousepressed(x, y, button)
    mouseX, mouseY = x, y
    
    if currentScreen == "home" then
        if x >= playButton.x and x <= playButton.x + playButton.w and
           y >= playButton.y and y <= playButton.y + playButton.h then
            startGame()
        end
    elseif currentScreen == "game" then
        if x >= backButton.x and x <= backButton.x + backButton.w and
           y >= backButton.y and y <= backButton.y + backButton.h then
            currentScreen = "home"
        end
    end
end

function love.mousemove(x, y)
    mouseX, mouseY = x, y
end

function startGame()
    deck = Deck:new()
    deck:shuffle()
    playerHand = deck:deal(10)
    dealerHand = deck:deal(10)
    Deck:sortByValue(playerHand)
    Deck:sortByValue(dealerHand)
    currentScreen = "game"
end

function drawHome()
    love.graphics.setColor(218/255, 165/255, 32/255, 255)
    love.graphics.setNewFont(48)
    love.graphics.print("CASINO", 220, 80)
    
    local hovering = mouseX >= playButton.x and mouseX <= playButton.x + playButton.w and
                   mouseY >= playButton.y and mouseY <= playButton.y + playButton.h
    
    if hovering then
        love.graphics.setColor(255/255, 215/255, 0/255, 255)
    else
        love.graphics.setColor(100/255, 100/255, 100/255, 255)
    end
    love.graphics.rectangle("fill", playButton.x, playButton.y, playButton.w, playButton.h)
    
    love.graphics.setColor(218/255, 165/255, 32/255, 255)
    love.graphics.setNewFont(20)
    love.graphics.print("PLAY", playButton.x + 28, playButton.y + 10)
end

function drawGame()
    drawHandArea(dealerHand, 20, true)
    drawHandArea(playerHand, 250, false)
    
    local hovering = mouseX >= backButton.x and mouseX <= backButton.x + backButton.w and
                   mouseY >= backButton.y and mouseY <= backButton.y + backButton.h
    
    if hovering then
        love.graphics.setColor(255/255, 215/255, 0/255, 255)
    else
        love.graphics.setColor(100/255, 100/255, 100/255, 255)
    end
    love.graphics.rectangle("fill", backButton.x, backButton.y, backButton.w, backButton.h)
    
    love.graphics.setColor(218/255, 165/255, 32/255, 255)
    love.graphics.setNewFont(20)
    love.graphics.print("BACK", backButton.x + 25, backButton.y + 10)
end

function drawHandArea(hand, startY, isDealer)
    love.graphics.setColor(46/255, 125/255, 50/255)
    love.graphics.rectangle("fill", 0, startY, 640, 100)
    
    local numCards = #hand
    if numCards == 0 then return end
    
    local handWidth = CARD_WIDTH + (numCards - 1) * (CARD_WIDTH - CARD_OVERLAP)
    local startX = (640 - handWidth) / 2
    
    for i, card in ipairs(hand) do
        local x = startX + (i - 1) * (CARD_WIDTH - CARD_OVERLAP)
        card:draw(x, startY + 5, CARD_WIDTH, CARD_HEIGHT)
    end
end