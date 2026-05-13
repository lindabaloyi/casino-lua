local Button = require("src.ui.Button")
local json = require("dkjson")

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
    log("LobbyScreen:load() - attempting connection")
    if self.network:connect() then
        self.status = "Connected! Waiting for opponent..."
        log("Connected - sending join_lobby")
        self.network:send({type = "join_lobby"})
    else
        self.status = "Failed to connect to server.\nCheck game.log for details.\nPress ESC to return."
        log("LobbyScreen:connect() failed")
    end
end

function LobbyScreen:update(dt, gameState, mouseX, mouseY)
    if not self.network.connected then
        log("Lobby update - not connected, status: " .. self.status)
        return
    end

    self.network:update()

    local msg = self.network:getNextMessage()
    while msg do
        log("Lobby received: " .. json.encode(msg))

        if msg.type == "connected" then
            self.network.playerId = msg.playerId
            self.status = "Connected! Player ID: " .. msg.playerId .. ". Waiting for opponent..."
            log("Assigned player ID: " .. msg.playerId)

        elseif msg.type == "room_joined" then
            if msg.roomId and msg.playerIndex then
                self.network.roomId = msg.roomId
                self.network.playerIndex = msg.playerIndex
                self.status = "Matched! Room " .. msg.roomId .. ", you are Player " .. msg.playerIndex
                log("Joined room " .. msg.roomId .. " as player " .. msg.playerIndex .. ", opponent: " .. (msg.opponentId or "unknown"))

                local gameBoard = self.screenManager:getScreen("game")
                if gameBoard then
                    gameBoard:startMultiplayer(
                        msg.roomId,
                        msg.playerIndex,
                        self.network
                    )
                    self.screenManager:switch("game")
                else
                    log("ERROR: gameBoard is nil")
                    self.status = "Error: Game board not found. Press ESC."
                end
            else
                log("WARNING: room_joined missing required fields: " .. json.encode(msg))
            end
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