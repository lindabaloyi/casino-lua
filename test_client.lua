-- test_client.lua - standalone test client (run with regular Lua, not LÖVE)
local socket = require("socket")
local json = require("dkjson")

local client = socket.tcp()
client:connect("localhost", 12345)
client:settimeout(5)

print("Connecting to server...")

while true do
    local line = client:receive()
    if line then
        local msg = json.decode(line)
        print("Received: " .. json.encode(msg))

        if msg.type == "connected" then
            print("My player ID: " .. msg.playerId)
            print("Joining lobby...")
            client:send(json.encode({type = "join_lobby"}) .. "\n")
        elseif msg.type == "room_joined" then
            print("Joined room " .. msg.roomId .. " as player " .. msg.playerIndex)
            print("Opponent ID: " .. msg.opponentId)
            break
        end
    end
end

print("Test complete - socket connection successful!")
client:close()