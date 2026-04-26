local function execute(gameState, payload, playerIndex)
    local stackIndex = payload.stackIndex

    log("[AcceptTemp] ===========================================")
    log("[AcceptTemp] Attempting to accept temp stack at index: " .. tostring(stackIndex))
    log("[AcceptTemp] Player ID: " .. playerIndex)

    if not stackIndex then
        log("[AcceptTemp] FAIL: Missing stackIndex")
        return false, "Missing stackIndex"
    end

    local stack = gameState.tableCards[stackIndex]
    if not stack then
        log("[AcceptTemp] FAIL: No stack found at index")
        return false, "No stack found at index"
    end

    if stack.type ~= "temp_stack" then
        log("[AcceptTemp] FAIL: Not a temp stack (type=" .. tostring(stack.type) .. ")")
        return false, "Not a temp stack"
    end

    if stack.owner ~= playerIndex then
        log("[AcceptTemp] FAIL: Owner mismatch (owner=" .. tostring(stack.owner) .. ", player=" .. playerIndex .. ")")
        return false, "You do not own this temp stack"
    end

    -- Log stack info before validation
    log("[AcceptTemp] --- Build Info ---")
    log("[AcceptTemp] Stack value: " .. stack.value)
    log("[AcceptTemp] Stack owner: " .. tostring(stack.owner))
    log("[AcceptTemp] Stack source: " .. tostring(stack.source))
    log("[AcceptTemp] Cards in build:")
    for i, card in ipairs(stack.cards) do
        local cardInfo = "  [" .. i .. "] " .. tostring(card.rank) .. tostring(card.suit) .. " (value: " .. card.value .. ", source: " .. tostring(card.source) .. ")"
        log("[AcceptTemp] " .. cardInfo)
    end
    local totalValue = 0
    for _, card in ipairs(stack.cards) do
        totalValue = totalValue + card.value
    end
    log("[AcceptTemp] Sum of card values: " .. totalValue)

    -- Validation 1: Must have at least one card from hand
    local hasHandCard = false
    for _, card in ipairs(stack.cards) do
        if card.source == 'hand' then
            hasHandCard = true
            break
        end
    end

    log("[AcceptTemp] --- Validation ---")
    log("[AcceptTemp] Has hand card: " .. tostring(hasHandCard))

    if not hasHandCard then
        log("[AcceptTemp] FAIL: No card from hand in build")
        return false, "Cannot accept build - must contain at least one card from your hand"
    end

    -- Validation 2: Player should have cards to cover the build
    log("[AcceptTemp] Player hand size: " .. #gameState.playerHand)
    if #gameState.playerHand == 0 then
        log("[AcceptTemp] FAIL: No cards in hand")
        return false, "No cards in hand to cover the build"
    end

    -- Validation 3: Verify build value matches sum of cards
    if totalValue ~= stack.value then
        log("[AcceptTemp] WARNING: Build value mismatch! (value: " .. stack.value .. ", sum: " .. totalValue .. ")")
    end

    log("[AcceptTemp] Validation: PASSED")

    -- Convert temp stack to build stack
    stack.type = "build_stack"
    stack.value = stack.value
    stack.need = stack.value

    -- Remove source tracking (not needed in build stack)
    for _, card in ipairs(stack.cards) do
        card.source = nil
    end

    log("[AcceptTemp] --- Build Accepted ---")
    log("[AcceptTemp] Build type: temp_stack -> build_stack")
    log("[AcceptTemp] Build value: " .. stack.value)
    log("[AcceptTemp] Cards now in build:")
    for i, card in ipairs(stack.cards) do
        local cardInfo = "  [" .. i .. "] " .. tostring(card.rank) .. tostring(card.suit) .. " (value: " .. card.value .. ")"
        log("[AcceptTemp] " .. cardInfo)
    end
    log("[AcceptTemp] ===========================================")

    return true, "Build accepted with value " .. stack.value
end

return { execute = execute }