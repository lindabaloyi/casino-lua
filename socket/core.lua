-- socket/core.lua - LuaSocket C core module
-- This file loads the socket core DLL

local core = {}

-- Try to load the C extension
local ok, core_module = pcall(require, "socket.core")
if not ok then
    -- DLL not found - will need to be added manually
    core._DLL_MISSING = true
else
    -- Copy all functions from the C module
    for k, v in pairs(core_module) do
        core[k] = v
    end
end

return core