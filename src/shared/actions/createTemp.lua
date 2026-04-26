local function execute(gameState, payload, playerIndex)
    local card = payload.card
    local target = payload.target
    
    log("[CreateTemp] card=" .. tostring(card) .. " target=" .. tostring(target))
    
    if not card or not target then
        return false, "Missing card or target"
    end
    
    local player = gameState.players[playerIndex + 1]
    if not player then
        return false, "Invalid player index"
    end
    
    -- Remove target from tableCards
    for i, c in ipairs(gameState.tableCards) do
        if c == target then
            table.remove(gameState.tableCards, i)
            break
        end
    end
    
    -- Create temp stack
    table.insert(gameState.tableCards, {
        type = "temp_stack",
        cards = { target, card },
        value = target.value + card.value
    })
    
    -- Remove card from playerHand
    for i, c in ipairs(gameState.playerHand) do
        if c == card then
            table.remove(gameState.playerHand, i)
            break
        end
    end
    
    return true, "Temp stack created with value " .. (target.value + card.value)
end

return { execute = execute }