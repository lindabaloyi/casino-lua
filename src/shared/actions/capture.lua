local function execute(gameState, tempStack, playerIndex)
    if not tempStack or tempStack.type ~= "temp_stack" then
        return false, "No temp stack to capture"
    end
    
    log("[Capture] stack value=" .. tostring(tempStack.value))
    
    local player = gameState.players[playerIndex + 1]
    if not player then
        return false, "Invalid player index"
    end
    
    for i, item in ipairs(gameState.tableCards) do
        if item == tempStack then
            table.remove(gameState.tableCards, i)
            break
        end
    end
    
    if not player.captures then player.captures = {} end
    for _, card in ipairs(tempStack.cards) do
        table.insert(player.captures, card)
    end
    
    return true, "Captured temp stack with value " .. tempStack.value
end

return { execute = execute }