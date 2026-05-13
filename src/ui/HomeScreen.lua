local Button = require("src.ui.Button")

local HomeScreen = {}
HomeScreen.__index = HomeScreen

function HomeScreen:load()
    self.title = "CASINO"
    self.titleX = 220
    self.titleY = 80
    self.titleFont = 48
    
    self.playButton = Button:new(270, 150, 100, 40, "PLAY")
    self.multiplayerButton = Button:new(270, 220, 140, 40, "MULTIPLAYER")
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

    self.multiplayerButton:draw(
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
    elseif self.multiplayerButton:clicked(x, y) then
        local NetworkManager = require("src.NetworkManager")
        -- For same machine: "127.0.0.1"
        -- For different machine: use server's IP address (e.g., "192.168.1.100")
        local host = "127.0.0.1"  -- Change to server IP for network play
        local network = NetworkManager:new(host, 12345)
        local LobbyScreen = require("src.ui.LobbyScreen")
        local lobby = LobbyScreen:new(screenManager, network)
        screenManager:addScreen("lobby", lobby)
        screenManager:switch("lobby")
    end
end

function HomeScreen:mousemove(x, y, gameState)
end

return HomeScreen