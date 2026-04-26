-- Simple trail action: drop a card from hand onto the table
local Trail = {}

---@param state table    Game state containing playerHand and tableCards
---@param card table     The card to trail (must have rank, suit)
---@return boolean success, string? message
function Trail.execute(state, card)
    if not state or not card then
        return false, "Missing state or card"
    end
    
    local hand = state.playerHand
    if not hand then
        return false, "No hand in game state"
    end
    
    -- Find exact card in hand
    local foundIndex = nil
    for i, c in ipairs(hand) do
        if c.rank == card.rank and c.suit == card.suit then
            foundIndex = i
            break
        end
    end
    
    if not foundIndex then
        return false, "Card not in hand"
    end
    
    -- Remove from hand
    local trailedCard = table.remove(hand, foundIndex)
    
    -- Add to table cards
    state.tableCards = state.tableCards or {}
    table.insert(state.tableCards, trailedCard)
    
    return true, "Card trailed"
end

return Trail