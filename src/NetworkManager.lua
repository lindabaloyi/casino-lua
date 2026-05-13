local json = require("dkjson")

local socket_ok, socket = pcall(require, "socket")
local socket_core_ok = false
if socket_ok then
    socket_core_ok = pcall(require, "socket.core")
end

local NetworkManager = {}
NetworkManager.__index = NetworkManager

function NetworkManager:new(host, port)
    local self = setmetatable({}, NetworkManager)
    self.host = host or "127.0.0.1"
    self.port = port or 12345
    self.connection = nil
    self.connected = false
    self.playerId = nil
    self.roomId = nil
    self.playerIndex = 0
    self.incoming = {}
    self.socketAvailable = socket_ok
    return self
end

function NetworkManager:isAvailable()
    return self.socketAvailable
end

function NetworkManager:connect()
    if not self.socketAvailable then
        log("Socket not available - LuaSocket DLLs not found")
        return false
    end

    self.connection = socket.tcp()
    self.connection:settimeout(5)

    local success, err = self.connection:connect(self.host, self.port)

    if not success then
        -- Retry once after a brief delay (for server startup delay)
        socket.sleep(0.5)
        success, err = self.connection:connect(self.host, self.port)
    end

    if not success then
        log("Connection failed to " .. self.host .. ":" .. self.port .. " - " .. tostring(err))
        return false
    end

    self.connection:settimeout(0)
    self.connected = true
    log("Connected to server at " .. self.host .. ":" .. self.port)
    return true
end

function NetworkManager:update()
    if not self.connected or not self.connection then return end

    while true do
        local line, err = self.connection:receive()
        if not line then break end
        local msg = json.decode(line)
        if msg then
            table.insert(self.incoming, msg)
            log("Received: " .. json.encode(msg))
        end
    end
end

function NetworkManager:send(msg)
    if self.connected and self.connection then
        local data = json.encode(msg) .. "\n"
        self.connection:send(data)
        log("Sent: " .. json.encode(msg))
    end
end

function NetworkManager:getNextMessage()
    return table.remove(self.incoming, 1)
end

function NetworkManager:disconnect()
    if self.connection then
        self.connection:close()
        self.connection = nil
    end
    self.connected = false
    log("Disconnected from server")
end

return NetworkManager