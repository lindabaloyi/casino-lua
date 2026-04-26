local function execute(gameState, payload, playerIndex)
    local card = payload.card
    local targetStack = payload.target

    log("[captureOwn] ===========================================")
    log("[captureOwn] Attempting to capture own build...")
    log("[captureOwn] Player ID: " .. playerIndex)

    if not card then
        log("[captureOwn] FAIL: Missing card")
        return false, "Missing card"
    end

    if not targetStack then
        log("[captureOwn] FAIL: Missing target stack")
        return false, "Missing target stack"
    end

    log("[captureOwn] --- Card Being Played ---")
    log("[captureOwn] Card: " .. tostring(card.rank) .. tostring(card.suit) .. " (value: " .. card.value .. ")")

    log("[captureOwn] --- Target Build Info ---")
    log("[captureOwn] Stack type: " .. tostring(targetStack.type))
    log("[captureOwn] Stack value: " .. tostring(targetStack.value))
    log("[captureOwn] Stack owner: " .. tostring(targetStack.owner))

    if targetStack.type ~= "build_stack" and targetStack.type ~= "temp_stack" then
        log("[captureOwn] FAIL: Target is not a build stack (type=" .. tostring(targetStack.type) .. ")")
        return false, "Target is not a build stack"
    end

    if targetStack.owner ~= playerIndex then
        log("[captureOwn] FAIL: Build not owned by player (owner=" .. tostring(targetStack.owner) .. ", player=" .. playerIndex .. ")")
        return false, "You do not own this build - use captureOpponent"
    end

    log("[captureOwn] Cards in target build:")
    local buildCards = targetStack.cards or {}
    for i, c in ipairs(buildCards) do
        log("[captureOwn]   [" .. i .. "] " .. tostring(c.rank) .. tostring(c.suit) .. " (value: " .. c.value .. ")")
    end

    local buildValue = targetStack.value or 0

    log("[captureOwn] --- Validation ---")
    log("[captureOwn] Build value: " .. buildValue)
    log("[captureOwn] Playing card value: " .. card.value)

    local canCapture = false

    if buildCards and #buildCards > 0 then
        local firstCardRank = buildCards[1].rank
        local allSameRank = true
        for _, c in ipairs(buildCards) do
            if c.rank ~= firstCardRank then
                allSameRank = false
                break
            end
        end

        if allSameRank then
            log("[captureOwn] Build is same-rank multi-card")
            local sum = 0
            for _, c in ipairs(buildCards) do
                sum = sum + c.value
            end
            local possibleValues = {sum}
            if firstCardRank == 1 then
                table.insert(possibleValues, 14 + sum - 1)
            end

            log("[captureOwn] Possible capture values: " .. table.concat(possibleValues, ", "))

            for _, v in ipairs(possibleValues) do
                if v == card.value then
                    canCapture = true
                    break
                end
            end

            if not canCapture then
                log("[captureOwn] FAIL: Card value " .. card.value .. " not in possible values [" .. table.concat(possibleValues, ", ") .. "]")
                return false, "Cannot capture - card value doesn't match build"
            end
        else
            if card.value == buildValue then
                canCapture = true
            else
                log("[captureOwn] FAIL: Card value " .. card.value .. " != build value " .. buildValue)
                return false, "Cannot capture - values don't match"
            end
        end
    else
        if card.value == buildValue then
            canCapture = true
        end
    end

    log("[captureOwn] Validation result: " .. tostring(canCapture))

    if not canCapture then
        log("[captureOwn] FAIL: Cannot capture build with this card")
        return false, "Cannot capture build with this card"
    end

    if not card.rank or not card.suit then
        log("[captureOwn] FAIL: Invalid card in hand")
        return false, "Invalid card"
    end

    local handIdx = -1
    for i, c in ipairs(gameState.playerHand) do
        if c.rank == card.rank and c.suit == card.suit then
            handIdx = i
            break
        end
    end

    if handIdx == -1 then
        log("[captureOwn] FAIL: Card not in player hand")
        return false, "Card not in hand"
    end

    table.remove(gameState.playerHand, handIdx)

    local stackIdx = -1
    for i, item in ipairs(gameState.tableCards) do
        if item == targetStack then
            stackIdx = i
            break
        end
    end

    if stackIdx == -1 then
        log("[captureOwn] FAIL: Build stack not found on table")
        table.insert(gameState.playerHand, card)
        return false, "Build stack not found"
    end

    table.remove(gameState.tableCards, stackIdx)

    local player = gameState.players[playerIndex + 1]
    if not player.captures then
        player.captures = {}
    end

    for _, c in ipairs(buildCards) do
        table.insert(player.captures, c)
    end
    table.insert(player.captures, card)

    log("[captureOwn] --- Build Captured ---")
    log("[captureOwn] Cards captured: " .. (#buildCards + 1))
    log("[captureOwn] Player captures now: " .. #player.captures)
    log("[captureOwn] ===========================================")

    return true, "Captured build with value " .. buildValue
end

return { execute = execute }