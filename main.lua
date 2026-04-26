local ScreenManager = require("src.ScreenManager")
local screenManager = nil

_G.log = function(msg)
    local file = io.open("game.log", "a")
    if file then
        file:write(os.date("%H:%M:%S") .. " " .. msg .. "\n")
        file:close()
    end
    print(msg)
end

function love.load()
    os.remove("game.log")
    log("Game loaded")
    love.window.setTitle("Casino")
    love.window.setMode(896, 414, { resizable = false, fullscreen = false })
    math.randomseed(os.time())
    
    screenManager = ScreenManager:new()
    screenManager:switch("game")
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

function love.mousedragged(x, y, dx, dy)
    screenManager:mousedragged(x, y, dx, dy)
end

function love.mousereleased(x, y, button)
    screenManager:mousereleased(x, y, button)
end