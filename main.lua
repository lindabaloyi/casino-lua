local ScreenManager = require("src.ScreenManager")
local screenManager = nil

function love.load()
    love.window.setTitle("Casino")
    love.window.setMode(896, 414, { resizable = false, fullscreen = false })
    math.randomseed(os.time())
    
    screenManager = ScreenManager:new()
    screenManager:switch("home")
end

function love.update(dt)
    screenManager:update(dt)
end

function love.draw()
    screenManager:draw()
end

function love.mousepressed(x, y, button)
    screenManager:mousepressed(x, y, button)
end

function love.mousemove(x, y)
    screenManager:mousemove(x, y)
end