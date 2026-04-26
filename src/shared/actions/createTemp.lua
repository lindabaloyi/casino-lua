local function execute(gameState, payload, playerIndex)
    local card = payload.card
    local target = payload.target
    local source = payload.source
    
    log("[CreateTemp] card=" .. tostring(card) .. " target=" .. tostring(target) .. " source=" .. tostring(source))
    
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
    
    -- Sort: higher value on bottom (index 1), lower value on top (index 2)
    local bottom, top
    if card.value > target.value then
        bottom = card
        top = target
    else
        bottom = target
        top = card
    end
    
    -- Remove card based on source
    if source == 'table' then
        -- Remove card from tableCards (it's already been removed from there, but we need to update index)
        for i, c in ipairs(gameState.tableCards) do
            if c == card then
                table.remove(gameState.tableCards, i)
                break
            end
        end
    else
        -- Remove card from playerHand
        for i, c in ipairs(gameState.playerHand) do
            if c == card then
                table.remove(gameState.playerHand, i)
                break
            end
        end
    end
    
    -- Create temp stack
    table.insert(gameState.tableCards, {
        type = "temp_stack",
        cards = { bottom, top },
        value = bottom.value + top.value
    })
    
    return true, "Temp stack created with value " .. (bottom.value + top.value)
end

return { execute = execute }