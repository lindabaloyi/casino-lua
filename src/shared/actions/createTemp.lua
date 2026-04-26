local function execute(gameState, payload, playerIndex)
    local card = payload.card
    local target = payload.target
    
    if not card or not target then
        return false, "Missing card or target"
    end
    
    local player = gameState.players[playerIndex + 1]
    if not player then
        return false, "Invalid player index"
    end
    
    table.insert(gameState.tableCards, {
        type = "temp_stack",
        cards = { target, card },
        value = target:value() + card:value()
    })
    
    for i, c in ipairs(gameState.playerHand) do
        if c == card then
            table.remove(gameState.playerHand, i)
            break
        end
    end
    
    return true, "Temp stack created with value " .. (target:value() + card:value())
end

return { execute = execute }