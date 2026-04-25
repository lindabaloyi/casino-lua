local Card = {}
Card.__index = Card

local SUIT_IMAGES = {
    H = love.graphics.newImage("assets/Heart.png"),
    D = love.graphics.newImage("assets/Diamond.png"),
    C = love.graphics.newImage("assets/Clubs.png"),
    S = love.graphics.newImage("assets/Spade.png")
}

for _, img in pairs(SUIT_IMAGES) do
    img:setFilter("linear", "linear")
end

local CORNER_R = 10

function Card:new(rank, suit)
    local obj = setmetatable({}, Card)
    obj.rank = rank
    obj.suit = suit
    obj.suitImage = SUIT_IMAGES[suit]
    
    if rank == 1 then
        obj.value = 1
    elseif rank >= 10 then
        obj.value = 10
    else
        obj.value = rank
    end
    
    return obj
end

function Card:getSuitColor()
    if self.suit == "H" or self.suit == "D" then
        return 0.9, 0.22, 0.21
    else
        return 0.13, 0.13, 0.13
    end
end

local function roundedRect(mode, x, y, w, h, r)
    local ok, _ = pcall(love.graphics.rectangle, mode, x, y, w, h, r, r)
    if not ok then
        love.graphics.rectangle(mode, x, y, w, h)
    end
end

function Card:draw(x, y, width, height)
    local r, g, b = self:getSuitColor()
    
    love.graphics.setColor(1, 1, 1, 1)
    roundedRect("fill", x, y, width, height, CORNER_R)
    
    love.graphics.setColor(0.97, 0.97, 1.0, 0.5)
    roundedRect("fill", x, y, width, height / 2, CORNER_R)
    
    love.graphics.setColor(0.75, 0.75, 0.80, 1)
    roundedRect("line", x, y, width, height, CORNER_R)
    
    local fontMedium = love.graphics.newFont(20)
    local fontSmall = love.graphics.newFont(14)
    
    love.graphics.setColor(r, g, b, 1)
    love.graphics.setFont(fontMedium)
    love.graphics.print(tostring(self.rank), x + 8, y + 6)
    
    love.graphics.setFont(fontSmall)
    if self.suitImage then
        local function drawSuitScaled(posX, posY, maxW, maxH)
            local imgW = self.suitImage:getWidth()
            local imgH = self.suitImage:getHeight()
            local scale = math.min(maxW / imgW, maxH / imgH)
            love.graphics.draw(self.suitImage, posX, posY, 0, scale, scale)
        end
        
        drawSuitScaled(x + 8, y + 26, 16, 16)
    end
    
    love.graphics.push()
    love.graphics.translate(x + width - 8, y + height - 8)
    love.graphics.rotate(math.pi)
    love.graphics.setColor(r, g, b, 1)
    love.graphics.setFont(fontMedium)
    love.graphics.print(tostring(self.rank), 0, 0)
    love.graphics.setFont(fontSmall)
    if self.suitImage then
        local imgW = self.suitImage:getWidth()
        local imgH = self.suitImage:getHeight()
        local scale = math.min(16 / imgW, 16 / imgH)
        love.graphics.draw(self.suitImage, 0, 20, 0, scale, scale)
    end
    love.graphics.pop()
    
    love.graphics.setColor(1, 1, 1)
end

function Card:getDisplayString()
    return tostring(self.rank) .. self.suit
end

return Card