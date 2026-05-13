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
    print("Attempting to bind server to port " .. PORT .. "...")
    local bind_result, bind_err = pcall(function()
        server = socket.bind("0.0.0.0", PORT)
        server:settimeout(0)
    end)

    if not bind_result then
        print("ERROR: Failed to bind server: " .. tostring(bind_err))
    else
        print("Server started on port " .. PORT)
        print("Server listening on all interfaces (0.0.0.0)")
    end
end

function love.update(dt)
    local newClient = server:accept()
    if newClient then
        newClient:settimeout(0)
        local pid = nextPlayerId
        nextPlayerId = nextPlayerId + 1

        print("New connection accepted, assigning player ID: " .. pid)

        clients[pid] = {
            id = pid,
            socket = newClient,
            status = "connected",
            roomId = nil
        }

        sendToClient(clients[pid], {type = "connected", playerId = pid})
        print("Player " .. pid .. " connected - sent welcome message")
    end

    for pid, player in pairs(clients) do
        if not player.socket then
            print("WARNING: Player " .. pid .. " has no socket, skipping")
            goto continue
        end

        local line, err = player.socket:receive()
        if line then
            print("Received from player " .. pid .. ": " .. line)
            local msg = json.decode(line)
            if msg then
                print("Player " .. pid .. " sent type: " .. tostring(msg.type))

                if msg.type == "join_lobby" then
                    player.status = "waiting"
                    print("Player " .. pid .. " joined lobby - attempting to match")
                    matchPlayers()
                elseif msg.type == "chat" then
                    print("Chat message from player " .. pid)
                    local room = rooms[player.roomId]
                    if room then
                        broadcastToRoom(player.roomId, {
                            type = "chat",
                            playerId = pid,
                            message = msg.message
                        })
                    else
                        print("Player " .. pid .. " not in a room")
                    end
                end
            end
        elseif err and err ~= "timeout" then
            print("Player " .. pid .. " disconnected: " .. err)
            player.socket:close()
            clients[pid] = nil
        end

        ::continue::
    end
end

function love.draw()
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Casino Server Running on port " .. PORT, 10, 10)
    love.graphics.print("Players connected: " .. nextPlayerId - 1, 10, 30)
end

function sendToClient(player, msg)
    if not player or not player.socket then
        print("ERROR: sendToClient - invalid player or socket is nil")
        return
    end
    local data = json.encode(msg) .. "\n"
    local success, err = pcall(function() player.socket:send(data) end)
    if not success then
        print("ERROR: Failed to send to player: " .. tostring(err))
    end
end

function broadcastToRoom(roomId, msg)
    if not rooms[roomId] then
        print("ERROR: Room " .. roomId .. " does not exist")
        return
    end
    print("Broadcasting to room " .. roomId .. ": " .. json.encode(msg))
    for _, player in ipairs(rooms[roomId].players) do
        sendToClient(player, msg)
    end
end

function matchPlayers()
    local waiting = {}
    print("Matching players - checking " .. #clients .. " clients")
    for pid, player in pairs(clients) do
        print("Player " .. pid .. " status: " .. tostring(player.status))
        if player.status == "waiting" then
            table.insert(waiting, player)
        end
    end

    print("Players waiting: " .. #waiting)

    if #waiting >= 2 then
        local roomId = nextRoomId
        nextRoomId = nextRoomId + 1

        print("Creating room " .. roomId .. " with players " .. waiting[1].id .. " and " .. waiting[2].id)

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
        print("Sending room_joined to player 1")
        sendToClient(waiting[1], roomMsg)

        roomMsg.playerIndex = 2
        roomMsg.opponentId = waiting[1].id
        print("Sending room_joined to player 2")
        sendToClient(waiting[2], roomMsg)

        print("Room " .. roomId .. " created: Player " .. waiting[1].id .. " vs Player " .. waiting[2].id)
    end
end