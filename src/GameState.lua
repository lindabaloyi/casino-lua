local Card = require("src.Card")
local Deck = require("src.Deck")

local GameState = {}
GameState.__index = GameState

function GameState:new()
    local obj = {}
    obj.deck = nil
    obj.playerHand = {}
    obj.dealerHand = {}
    obj.tableCards = {}
    obj.players = {
        { name = "Player", captures = {} },
        { name = "Dealer", captures = {} }
    }
    return setmetatable(obj, GameState)
end

function GameState:start()
    self.deck = Deck:new()
    self.deck:shuffle()
    self.playerHand = self.deck:deal(10)
    self.dealerHand = self.deck:deal(10)
    self.tableCards = {}
    Deck:sortByValue(self.playerHand)
    Deck:sortByValue(self.dealerHand)
end

return GameState