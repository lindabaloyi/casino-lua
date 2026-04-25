local Button = require("src.ui.Button")

local HomeScreen = {}
HomeScreen.__index = HomeScreen

function HomeScreen:load()
    self.title = "CASINO"
    self.titleX = 220
    self.titleY = 80
    self.titleFont = 48
    
    self.playButton = Button:new(270, 150, 100, 40, "PLAY")
end

function HomeScreen:update(dt, gameState, mouseX, mouseY)
end

function HomeScreen:draw(gameState, mouseX, mouseY)
    love.graphics.setBackgroundColor(46/255, 125/255, 50/255)
    love.graphics.clear()
    
    love.graphics.setColor(218/255, 165/255, 32/255, 255)
    love.graphics.setNewFont(self.titleFont)
    love.graphics.print(self.title, self.titleX, self.titleY)
    
    self.playButton:draw(
        mouseX,
        mouseY,
        {255/255, 215/255, 0/255, 255},
        {100/255, 100/255, 100/255, 255},
        {218/255, 165/255, 32/255, 255}
    )
end

function HomeScreen:mousepressed(x, y, button, screenManager)
    if self.playButton:clicked(x, y) then
        screenManager:switch("game")
    end
end

function HomeScreen:mousemove(x, y, gameState)
end

return HomeScreen