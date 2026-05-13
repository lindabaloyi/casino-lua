local Button = require("src.ui.Button")

local LobbyScreen = {}
LobbyScreen.__index = LobbyScreen

function LobbyScreen:new(screenManager, networkManager)
    local self = setmetatable({}, LobbyScreen)
    self.screenManager = screenManager
    self.network = networkManager
    self.status = "Connecting to server..."
    return self
end

function LobbyScreen:load()
    if self.network:connect() then
        self.status = "Connected. Waiting for opponent..."
        self.network:send({type = "join_lobby"})
    else
        self.status = "Failed to connect to server.\nPress ESC to return."
    end
end

function LobbyScreen:update(dt, gameState, mouseX, mouseY)
    if not self.network.connected then return end

    self.network:update()

    local msg = self.network:getNextMessage()
    while msg do
        log("Lobby received: " .. json.encode(msg))

        if msg.type == "connected" then
            self.network.playerId = msg.playerId
            log("Assigned player ID: " .. msg.playerId)

        elseif msg.type == "room_joined" then
            self.network.roomId = msg.roomId
            self.network.playerIndex = msg.playerIndex
            log("Joined room " .. msg.roomId .. " as player " .. msg.playerIndex)

            local gameBoard = self.screenManager:getScreen("game")
            gameBoard:startMultiplayer(
                msg.roomId,
                msg.playerIndex,
                self.network
            )
            self.screenManager:switch("game")
        end

        msg = self.network:getNextMessage()
    end
end

function LobbyScreen:draw(gameState, mouseX, mouseY)
    love.graphics.setBackgroundColor(0.2, 0.2, 0.2)
    love.graphics.clear()

    love.graphics.setColor(1, 1, 1)
    love.graphics.setNewFont(24)
    love.graphics.printf(self.status, 0, 200, love.graphics.getWidth(), "center")

    if not self.network.connected then
        love.graphics.setNewFont(16)
        love.graphics.printf("Press ESC to go back", 0, 250, love.graphics.getWidth(), "center")
    end
end

function LobbyScreen:mousepressed(x, y, button, screenManager)
end

function LobbyScreen:keypressed(key)
    if key == "escape" then
        self.network:disconnect()
        self.screenManager:switch("home")
    end
end

return LobbyScreen