local Finder = { _handlers = {} }

function Finder.register(name, fn)
    Finder._handlers[name] = fn
end

function Finder.find(name, x, y, tableCards, ...)
    local fn = Finder._handlers[name]
    if fn then return fn(x, y, tableCards, ...) end
    return nil
end

function Finder.findAny(x, y, tableCards, ...)
    for name, fn in pairs(Finder._handlers) do
        local result = fn(x, y, tableCards, ...)
        if result then
            return { type = name, data = result }
        end
    end
    return nil
end

return Finder