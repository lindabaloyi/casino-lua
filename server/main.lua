print("=== SERVER MAIN.LUA LOADED ===")

local json = require("dkjson")
local socket_ok, socket = pcall(require, "socket")
if not socket_ok then
    print("ERROR: LuaSocket not found. Make sure socket.lua and DLLs are in the right path.")
    os.exit(1)
end
print("LuaSocket loaded successfully")

local PORT = 12345

local clients = {}
local lobby = {}
local games = {}
local nextPlayerId = 1
local nextGameId = 1

local function sendToClient(pid, msg)
    local c = clients[pid]
    if not c or not c.sock then
        print("sendToClient: client " .. tostring(pid) .. " not found")
        return false
    end
    local json_str = json.encode(msg)
    print("Sending to " .. pid .. ": " .. json_str)
    local ok, err = c.sock:send(json_str .. "\n")
    if not ok then
        print("Send error: " .. tostring(err))
        return false
    end
    return true
end

local function broadcastToGame(gameId, msg)
    local game = games[gameId]
    if not game then return false end
    for _, pid in ipairs(game.players) do
        sendToClient(pid, msg)
    end
    return true
end

local function createInitialGameState()
    print("Creating initial game state")
    local suits = {"hearts","diamonds","clubs","spades"}
    local ranks = {"A","2","3","4","5","6","7","8","9","10","J","Q","K"}
    local deck = {}
    for _,s in ipairs(suits) do
        for i,r in ipairs(ranks) do
            table.insert(deck, {suit=s, rank=r, value=i})
        end
    end
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
    local tableCards = {}
    for i=1,4 do table.insert(tableCards, table.remove(deck)) end
    local playerHands = { {}, {} }
    for i=1,10 do
        table.insert(playerHands[1], table.remove(deck))
        table.insert(playerHands[2], table.remove(deck))
    end
    return {
        players = {
            { hand = playerHands[1], captures = {} },
            { hand = playerHands[2], captures = {} }
        },
        tableCards = tableCards,
        currentTurn = 1
    }
end

local function startGame(p1, p2)
    print(string.format("startGame called with %d and %d", p1, p2))
    local gameId = nextGameId
    nextGameId = nextGameId + 1
    local state = createInitialGameState()
    games[gameId] = {
        players = {p1, p2},
        state = state,
        turn = p1
    }
    local success = true
    for idx, pid in ipairs({p1, p2}) do
        local msg = {
            type = "game_start",
            gameId = gameId,
            playerIndex = idx,
            state = state
        }
        if not sendToClient(pid, msg) then
            print("Failed to send game_start to player " .. pid)
            success = false
            break
        end
    end
    if not success then
        games[gameId] = nil
        return false
    end
    print("Game " .. gameId .. " started successfully")
    return true
end

local function checkLobby()
    local waiting = {}
    for pid,_ in pairs(lobby) do
        table.insert(waiting, pid)
        if #waiting == 2 then break end
    end
    print("checkLobby: waiting players = " .. table.concat(waiting, ","))
    if #waiting == 2 then
        lobby[waiting[1]] = nil
        lobby[waiting[2]] = nil
        local ok, err = pcall(startGame, waiting[1], waiting[2])
        if not ok then
            print("Error starting game: " .. tostring(err))
            lobby[waiting[1]] = true
            lobby[waiting[2]] = true
        end
    end
end

local function processMessage(pid, msg)
    print("Received from " .. pid .. ": " .. json.encode(msg))
    if msg.type == "join_lobby" then
        if not lobby[pid] then
            lobby[pid] = true
            print("Player " .. pid .. " joined lobby")
            sendToClient(pid, {type = "room_joined", message = "Waiting for opponent"})
            checkLobby()
        end
    elseif msg.type == "game_action" then
        local game = games[msg.gameId]
        if not game then return end
        if game.turn ~= pid then
            sendToClient(pid, {type = "error", message = "Not your turn"})
            return
        end
        local other = (game.players[1] == pid) and game.players[2] or game.players[1]
        game.turn = other
        broadcastToGame(msg.gameId, {type = "state_update", state = game.state, turn = game.turn})
    end
end

print("Attempting to bind to 127.0.0.1:" .. PORT)
local server = socket.bind("127.0.0.1", PORT)
if not server then
    print("ERROR: Could not bind to port " .. PORT .. ". Is it already in use?")
    os.exit(1)
end
server:settimeout(0)
print("=== Server listening on 127.0.0.1:" .. PORT .. " ===")

while true do
    local client = server:accept()
    if client then
        client:settimeout(0)
        local pid = nextPlayerId
        nextPlayerId = nextPlayerId + 1
        clients[pid] = {sock = client, name = "Player"..pid}
        sendToClient(pid, {type = "connected", playerId = pid})
        print("Player " .. pid .. " connected")
    end

    for pid, data in pairs(clients) do
        local line, err = data.sock:receive()
        if line then
            local msg = json.decode(line)
            if msg then
                xpcall(function() processMessage(pid, msg) end, function(e)
                    print("Error in processMessage: " .. tostring(e))
                end)
            end
        elseif err and err ~= "timeout" then
            print("Player " .. pid .. " disconnected: " .. tostring(err))
            data.sock:close()
            clients[pid] = nil
            lobby[pid] = nil
        end
    end
    love.timer.sleep(0.01)
end