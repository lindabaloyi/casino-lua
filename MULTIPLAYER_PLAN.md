# Multiplayer Lobby System Implementation Plan

## Current Codebase Analysis

The game is a Love2D-based Cassino card game with the following structure:

- **main.lua**: Entry point, initializes ScreenManager and switches to "home" screen.
- **ScreenManager.lua**: Manages screen switching between "home" and "game".
- **HomeScreen.lua**: Displays title and "PLAY" button to start game.
- **GameBoard.lua**: Handles game rendering and input.
- **GameState.lua**: Manages game state (deck, hands, table cards, players).
- **InputHandler.lua**: Processes player actions (trail, capture, etc.).
- Various support modules for UI, actions, etc.

Currently, it's single-player: Player vs Dealer (static opponent).

## Proposed Multiplayer Architecture

Implement a client-server model:

- **Server**: Standalone Lua script using LuaSocket. Manages:
  - Player connections
  - Lobby system (wait for 2 players)
  - Game state synchronization
  - Turn management
- **Client**: Modified Love2D game that connects to server.
  - Lobby screen: Wait for opponent
  - Game screen: Sync with server, send moves, receive opponent moves

Networking Protocol:
- TCP connections for reliability.
- Message format: JSON-encoded tables (e.g., {"type": "join_lobby", "player_id": 1})
- Server broadcasts game state updates to both clients.

## Implementation Plan

### 1. Add Dependencies
- Install LuaSocket for networking.
- Add JSON library (e.g., dkjson) for message serialization.

### 2. Server Implementation
Create `server.lua` as a standalone script.

#### server.lua
```lua
local socket = require("socket")
local json = require("dkjson")  -- Assuming dkjson is available

local Server = {}
Server.__index = Server

function Server:new(port)
    local self = setmetatable({}, Server)
    self.port = port or 12345
    self.server = socket.bind("*", self.port)
    self.server:settimeout(0)
    self.clients = {}
    self.lobby = {}  -- List of waiting players
    self.games = {}  -- Active games: {game_id: {players: {id: client}, state: {...}}}
    self.next_player_id = 1
    self.next_game_id = 1
    print("Server started on port " .. self.port)
    return self
end

function Server:run()
    while true do
        local client = self.server:accept()
        if client then
            client:settimeout(0)
            local player_id = self.next_player_id
            self.next_player_id = self.next_player_id + 1
            self.clients[player_id] = client
            self.lobby[player_id] = true
            print("Player " .. player_id .. " connected")
            -- Send player_id to client
            self:send_to_client(player_id, {type = "connected", player_id = player_id})
            -- Try to start game if 2 players in lobby
            self:check_lobby()
        end
        self:handle_messages()
        socket.sleep(0.01)
    end
end

function Server:check_lobby()
    local players = {}
    for id, _ in pairs(self.lobby) do
        table.insert(players, id)
        if #players == 2 then break end
    end
    if #players == 2 then
        -- Start game
        local game_id = self.next_game_id
        self.next_game_id = self.next_game_id + 1
        self.games[game_id] = {
            players = {players[1], players[2]},
            state = self:create_initial_game_state(),
            current_turn = 1  -- Player 1 starts
        }
        -- Remove from lobby
        self.lobby[players[1]] = nil
        self.lobby[players[2]] = nil
        -- Notify players
        for i, pid in ipairs(players) do
            self:send_to_client(pid, {type = "game_start", game_id = game_id, player_index = i, state = self.games[game_id].state})
        end
        print("Game " .. game_id .. " started with players " .. players[1] .. " and " .. players[2])
    end
end

function Server:create_initial_game_state()
    -- Simplified game state initialization (adapt from GameState.lua)
    local deck = {}  -- Implement deck creation
    -- Shuffle, deal, etc.
    return {
        table_cards = {},
        players = {
            {hand = {}, captures = {}},
            {hand = {}, captures = {}}
        },
        current_player = 1
    }
end

function Server:handle_messages()
    for id, client in pairs(self.clients) do
        local data, err = client:receive()
        if data then
            local msg = json.decode(data)
            if msg then
                self:process_message(id, msg)
            end
        elseif err ~= "timeout" then
            print("Player " .. id .. " disconnected")
            self.clients[id] = nil
            self.lobby[id] = nil
            -- Handle game cleanup if needed
        end
    end
end

function Server:process_message(player_id, msg)
    if msg.type == "join_lobby" then
        self.lobby[player_id] = true
        self:check_lobby()
    elseif msg.type == "game_action" then
        -- Handle game actions (e.g., play card, capture)
        local game_id = msg.game_id
        local game = self.games[game_id]
        if game and game.current_turn == msg.player_index then
            -- Validate and apply action
            -- Update game.state
            -- Switch turn
            game.current_turn = 3 - game.current_turn  -- Toggle between 1 and 2
            -- Broadcast updated state to both players
            for _, pid in ipairs(game.players) do
                self:send_to_client(pid, {type = "state_update", state = game.state})
            end
        end
    end
end

function Server:send_to_client(player_id, msg)
    local client = self.clients[player_id]
    if client then
        local data = json.encode(msg)
        client:send(data .. "\n")
    end
end

-- Run the server
local server = Server:new()
server:run()
```

### 3. Client Modifications

#### Update main.lua to Connect to Server
```lua
-- main.lua (add networking)
local socket = require("socket")
local json = require("dkjson")

function love.load()
    -- ... existing code ...
    
    -- Connect to server
    self.client = socket.tcp()
    self.client:connect("localhost", 12345)  -- Server address
    self.client:settimeout(0)
    self.player_id = nil
    self.game_id = nil
    self.player_index = nil
    
    -- ... rest of load ...
end

function love.update(dt)
    -- ... existing ...
    
    -- Handle server messages
    local data, err = self.client:receive()
    if data then
        local msg = json.decode(data)
        if msg.type == "connected" then
            self.player_id = msg.player_id
            -- Switch to lobby or send join_lobby
            screenManager:switch("lobby")
        elseif msg.type == "game_start" then
            self.game_id = msg.game_id
            self.player_index = msg.player_index
            -- Initialize game with state
            screenManager:switch("game", msg.state)
        elseif msg.type == "state_update" then
            -- Update local game state
            gameState:update_from_server(msg.state)
        end
    end
end

-- Send messages to server
function send_to_server(msg)
    local data = json.encode(msg)
    client:send(data .. "\n")
end
```

#### Create LobbyScreen.lua
```lua
-- src/ui/LobbyScreen.lua
local LobbyScreen = {}
LobbyScreen.__index = LobbyScreen

function LobbyScreen:load()
    -- Send join_lobby to server
    send_to_server({type = "join_lobby"})
end

function LobbyScreen:draw()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Waiting for another player...", 300, 200)
end

-- ... other methods ...
```

#### Update ScreenManager to Handle Lobby
```lua
-- ScreenManager.lua
function ScreenManager:switch(screenName, ...)
    if screenName == "lobby" then
        self.currentScreen = require("src.ui.LobbyScreen")
    elseif screenName == "game" then
        -- Pass initial state or game_id
        self.gameState = GameState:new(...)
        self.currentScreen = require("src.ui.GameBoard")
    end
    self.currentScreen:load(...)
end
```

#### Modify InputHandler to Send Actions to Server
```lua
-- InputHandler.lua
function InputHandler:handleMouseReleased(x, y, button, gameState)
    -- ... existing action logic ...
    
    if success then
        -- Send action to server
        send_to_server({
            type = "game_action",
            game_id = game_id,
            player_index = player_index,
            action = {type = "play_card", card = card, ...}
        })
    end
end
```

#### Update GameState for Server Sync
```lua
-- GameState.lua
function GameState:update_from_server(state)
    self.table_cards = state.table_cards
    self.players = state.players
    -- etc.
end
```

### 4. Game State Synchronization
- Server maintains authoritative game state.
- Clients send actions, server validates and broadcasts updates.
- Clients are read-only except for sending their moves.

### 5. Testing and Deployment
- Run server separately: `lua server.lua`
- Run client: `love .`
- Handle disconnections, errors.

## Challenges and Considerations
- Latency: Card game actions are not time-sensitive, but sync delays possible.
- Security: Basic TCP; consider encryption for production.
- Scalability: Single server for multiple games; expand to multiple lobbies.
- Love2D Networking: Ensure LuaSocket is compatible.
- Turn Management: Server enforces turns to prevent cheating.

This plan provides a comprehensive foundation for multiplayer Cassino with lobby waiting.</content>
<parameter name="filePath">C:\Users\LB\Desktop\Linda Baloyi\MadGames\Lua Love2D\official-casino\MULTIPLAYER_PLAN.md