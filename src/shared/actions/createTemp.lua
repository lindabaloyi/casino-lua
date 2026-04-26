local function execute(gameState, payload, playerIndex)
    local card = payload.card
    local target = payload.target
    local source = payload.source

    log("[CreateTemp] ===========================================")
    log("[CreateTemp] Creating temp stack...")
    log("[CreateTemp] Player ID: " .. playerIndex)
    log("[CreateTemp] Source: " .. source)

    if not card or not target then
        log("[CreateTemp] FAIL: Missing card or target")
        return false, "Missing card or target"
    end

    local player = gameState.players[playerIndex + 1]
    if not player then
        log("[CreateTemp] FAIL: Invalid player index")
        return false, "Invalid player index"
    end

    -- Log the cards being combined
    log("[CreateTemp] --- Cards Being Combined ---")
    log("[CreateTemp] Card from " .. source .. ": " .. tostring(card.rank) .. tostring(card.suit) .. " (value: " .. card.value .. ")")
    log("[CreateTemp] Target on table: " .. tostring(target.rank) .. tostring(target.suit) .. " (value: " .. target.value .. ")")

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
        log("[CreateTemp] Bottom card (higher): " .. tostring(bottom.rank) .. tostring(bottom.suit))
        log("[CreateTemp] Top card (lower): " .. tostring(top.rank) .. tostring(top.suit))
    else
        bottom = target
        top = card
        log("[CreateTemp] Bottom card (higher): " .. tostring(bottom.rank) .. tostring(bottom.suit))
        log("[CreateTemp] Top card (lower): " .. tostring(top.rank) .. tostring(top.suit))
    end

    -- Mark source for each card (for validation in acceptTemp)
    bottom.source = source
    top.source = source == 'hand' and 'table' or 'hand'

    -- Remove card based on source
    if source == 'table' then
        -- Remove card from tableCards
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

    local buildValue = bottom.value + top.value

    -- Create temp stack with owner and source info
    table.insert(gameState.tableCards, {
        type = "temp_stack",
        cards = { bottom, top },
        value = buildValue,
        owner = playerIndex,
        source = source
    })

    log("[CreateTemp] --- Temp Stack Created ---")
    log("[CreateTemp] Stack type: temp_stack")
    log("[CreateTemp] Owner (player ID): " .. playerIndex)
    log("[CreateTemp] Build value: " .. buildValue)
    log("[CreateTemp] Cards in stack:")
    log("[CreateTemp]   [1] Bottom: " .. tostring(bottom.rank) .. tostring(bottom.suit) .. " (value: " .. bottom.value .. ", source: " .. tostring(bottom.source) .. ")")
    log("[CreateTemp]   [2] Top: " .. tostring(top.rank) .. tostring(top.suit) .. " (value: " .. top.value .. ", source: " .. tostring(top.source) .. ")")
    log("[CreateTemp] ===========================================")

    return true, "Temp stack created with value " .. buildValue
end

return { execute = execute }