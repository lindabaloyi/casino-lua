local Card = require("src.Card")

local Deck = {}
Deck.__index = Deck

local SUITS = {"C", "D", "H", "S"}
local RANKS = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}

function Deck:new()
    local obj = setmetatable({}, Deck)
    obj.cards = {}
    
    for _, suit in ipairs(SUITS) do
        for _, rank in ipairs(RANKS) do
            table.insert(obj.cards, Card:new(rank, suit))
        end
    end
    
    return obj
end

function Deck:shuffle()
    local n = #self.cards
    for i = n, 2, -1 do
        local j = math.random(i)
        self.cards[i], self.cards[j] = self.cards[j], self.cards[i]
    end
end

function Deck:deal(count)
    local dealt = {}
    for i = 1, count do
        if #self.cards > 0 then
            table.insert(dealt, table.remove(self.cards))
        end
    end
    return dealt
end

function Deck:sortByValue(cards)
    table.sort(cards, function(a, b)
        return a.value < b.value
    end)
    return cards
end

return Deck