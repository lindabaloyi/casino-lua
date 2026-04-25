local Button = {}
Button.__index = Button

function Button:new(x, y, w, h, text)
    local obj = {
        x = x,
        y = y,
        w = w,
        h = h,
        text = text
    }
    return setmetatable(obj, Button)
end

function Button:draw(mouseX, mouseY, hoverColor, normalColor, textColor)
    local hovering = self:isHovered(mouseX, mouseY)
    
    if hovering then
        love.graphics.setColor(hoverColor[1], hoverColor[2], hoverColor[3], hoverColor[4] or 1)
    else
        love.graphics.setColor(normalColor[1], normalColor[2], normalColor[3], normalColor[4] or 1)
    end
    
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
    
    love.graphics.setColor(textColor[1], textColor[2], textColor[3], textColor[4] or 1)
    love.graphics.print(self.text, self.x + 10, self.y + 10)
end

function Button:isHovered(mx, my)
    return mx >= self.x and mx <= self.x + self.w and
           my >= self.y and my <= self.y + self.h
end

function Button:clicked(mx, my)
    return self:isHovered(mx, my)
end

return Button