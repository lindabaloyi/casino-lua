local GameState = require("src.GameState")

local ScreenManager = {}
ScreenManager.__index = ScreenManager

function ScreenManager:new()
    local obj = {}
    obj.currentScreen = nil
    obj.gameState = GameState:new()
    obj.mouseX = 0
    obj.mouseY = 0
    return setmetatable(obj, ScreenManager)
end

function ScreenManager:switch(screenName, ...)
    if screenName == "home" then
        self.currentScreen = require("src.ui.HomeScreen")
    elseif screenName == "game" then
        self.gameState:start()
        self.currentScreen = require("src.ui.GameScreen")
    end
    self.currentScreen:load(...)
end

function ScreenManager:update(dt)
    if self.currentScreen and self.currentScreen.update then
        self.currentScreen:update(dt, self.gameState, self.mouseX, self.mouseY)
    end
end

function ScreenManager:draw()
    if self.currentScreen and self.currentScreen.draw then
        self.currentScreen:draw(self.gameState, self.mouseX, self.mouseY)
    end
end

function ScreenManager:mousepressed(x, y, button)
    self.mouseX = x
    self.mouseY = y
    if self.currentScreen and self.currentScreen.mousepressed then
        self.currentScreen:mousepressed(x, y, button, self)
    end
end

function ScreenManager:mousemove(x, y)
    self.mouseX = x
    self.mouseY = y
    if self.currentScreen and self.currentScreen.mousemove then
        self.currentScreen:mousemove(x, y)
    end
end

function ScreenManager:mousedragged(x, y, dx, dy)
    self.mouseX = x
    self.mouseY = y
    if self.currentScreen and self.currentScreen.mousedragged then
        self.currentScreen:mousedragged(x, y, dx, dy)
    end
end

function ScreenManager:mousereleased(x, y, button)
    self.mouseX = x
    self.mouseY = y
    if self.currentScreen and self.currentScreen.mousereleased then
        self.currentScreen:mousereleased(x, y, button, self)
    end
end

function ScreenManager:getMousePosition()
    return self.mouseX, self.mouseY
end

return ScreenManager