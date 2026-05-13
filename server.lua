local socket = require("socket")
local json = require("dkjson")

local clients = {}
local rooms = {}
local nextPlayerId = 1
local nextRoomId = 1

local PORT = 12345

local server = nil
local running = true

function love.load()
    server = socket.bind("*", PORT)
    server:settimeout(0)
    print("Server started on port " .. PORT)
end

function love.update(dt)
    local newClient = server:accept()
    if newClient then
        newClient:settimeout(0)
        local pid = nextPlayerId
        nextPlayerId = nextPlayerId + 1

        clients[pid] = {
            id = pid,
            socket = newClient,
            status = "connected",
            roomId = nil
        }

        sendToClient(newClient, {type = "connected", playerId = pid})
        print("Player " .. pid .. " connected")
    end

    for pid, player in pairs(clients) do
        local line, err = player.socket:receive()
        if line then
            local msg = json.decode(line)
            if msg then
                print("Player " .. pid .. " sent: " .. json.encode(msg))

                if msg.type == "join_lobby" then
                    player.status = "waiting"
                    print("Player " .. pid .. " joined lobby")
                    matchPlayers()
                elseif msg.type == "chat" then
                    local room = rooms[player.roomId]
                    if room then
                        broadcastToRoom(player.roomId, {
                            type = "chat",
                            playerId = pid,
                            message = msg.message
                        })
                    end
                end
            end
        elseif err ~= "timeout" then
            print("Player " .. pid .. " disconnected")
            player.socket:close()
            clients[pid] = nil
        end
    end
end

function love.draw()
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Casino Server Running on port " .. PORT, 10, 10)
    love.graphics.print("Players connected: " .. nextPlayerId - 1, 10, 30)
end

function sendToClient(client, msg)
    local data = json.encode(msg) .. "\n"
    client.socket:send(data)
end

function broadcastToRoom(roomId, msg)
    for _, player in ipairs(rooms[roomId].players) do
        sendToClient(player.client, msg)
    end
end

function matchPlayers()
    local waiting = {}
    for pid, player in pairs(clients) do
        if player.status == "waiting" then
            table.insert(waiting, player)
        end
    end

    if #waiting >= 2 then
        local roomId = nextRoomId
        nextRoomId = nextRoomId + 1

        rooms[roomId] = {
            players = {waiting[1], waiting[2]},
            status = "matched"
        }

        waiting[1].status = "in_room"
        waiting[1].roomId = roomId
        waiting[2].status = "in_room"
        waiting[2].roomId = roomId

        local roomMsg = {
            type = "room_joined",
            roomId = roomId,
            playerIndex = 1,
            opponentId = waiting[2].id
        }
        sendToClient(waiting[1].client, roomMsg)

        roomMsg.playerIndex = 2
        roomMsg.opponentId = waiting[1].id
        sendToClient(waiting[2].client, roomMsg)

        print("Room " .. roomId .. " created: Player " .. waiting[1].id .. " vs Player " .. waiting[2].id)
    end
end