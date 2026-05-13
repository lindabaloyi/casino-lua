-- dkjson.lua - minimal JSON encode/decode for Lua
-- Based on dkjson 2.5

local json = {}

function json.encode(obj, opts)
    local buf = {}
    local indent = opts and opts.indent or ""
    local indent_str = opts and opts.indent or ""

    local function encode(val)
        if type(val) == "nil" then
            table.insert(buf, "null")
        elseif type(val) == "boolean" then
            table.insert(buf, tostring(val))
        elseif type(val) == "number" then
            table.insert(buf, tostring(val))
        elseif type(val) == "string" then
            local s = val:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r')
            table.insert(buf, '"' .. s .. '"')
        elseif type(val) == "table" then
            local is_array = #val > 0
            local keys = {}
            for k in pairs(val) do
                if type(k) == "number" then
                    table.insert(keys, k)
                elseif type(k) == "string" then
                    table.insert(keys, k)
                end
            end
            table.sort(keys, function(a, b)
                if type(a) == "number" and type(b) == "number" then return a < b end
                return tostring(a) < tostring(b)
            end)

            table.insert(buf, "{")
            local first = true
            for _, k in ipairs(keys) do
                if not first then table.insert(buf, ",") end
                first = false
                if type(k) == "string" then
                    table.insert(buf, '"' .. k .. '":')
                else
                    table.insert(buf, tostring(k) .. ":")
                end
                encode(val[k])
            end
            table.insert(buf, "}")
        else
            table.insert(buf, '"' .. tostring(val) .. '"')
        end
    end

    encode(obj)
    return table.concat(buf)
end

local function skip_whitespace(str, pos)
    while pos <= #str and str:match("^%s", pos) do
        pos = pos + 1
    end
    return pos
end

local function parse_string(str, pos)
    local buf = {}
    pos = pos + 1
    while pos <= #str do
        local c = str:sub(pos, pos)
        if c == '"' then
            pos = pos + 1
            break
        elseif c == "\\" then
            pos = pos + 1
            local esc = str:sub(pos, pos)
            if esc == "n" then table.insert(buf, "\n")
            elseif esc == "r" then table.insert(buf, "\r")
            elseif esc == "t" then table.insert(buf, "\t")
            elseif esc == '"' then table.insert(buf, '"')
            elseif esc == "\\" then table.insert(buf, "\\")
            else table.insert(buf, esc) end
            pos = pos + 1
        else
            table.insert(buf, c)
            pos = pos + 1
        end
    end
    return table.concat(buf), pos
end

local function parse_number(str, pos)
    local start = pos
    if str:sub(pos, pos) == "-" then pos = pos + 1 end
    while pos <= #str and str:match("[0-9%.]", pos) do
        pos = pos + 1
    end
    return tonumber(str:sub(start, pos - 1)), pos
end

local function parse_value(str, pos)
    pos = skip_whitespace(str, pos)
    if pos > #str then return nil, pos end

    local c = str:sub(pos, pos)
    if c == "n" and str:sub(pos, pos + 3) == "null" then
        return nil, pos + 4
    elseif c == "t" and str:sub(pos, pos + 3) == "true" then
        return true, pos + 4
    elseif c == "f" and str:sub(pos, pos + 4) == "false" then
        return false, pos + 5
    elseif c == '"' then
        return parse_string(str, pos)
    elseif c == "{" then
        local obj = {}
        pos = pos + 1
        while true do
            pos = skip_whitespace(str, pos)
            if str:sub(pos, pos) == "}" then
                pos = pos + 1
                break
            end
            local key, new_pos = parse_value(str, pos)
            pos = skip_whitespace(str, new_pos)
            if str:sub(pos, pos) == ":" then
                pos = pos + 1
            end
            local val, val_pos = parse_value(str, pos)
            obj[key] = val
            pos = skip_whitespace(str, val_pos)
            if str:sub(pos, pos) == "," then
                pos = pos + 1
            end
        end
        return obj, pos
    elseif c == "[" then
        local arr = {}
        pos = pos + 1
        while true do
            pos = skip_whitespace(str, pos)
            if str:sub(pos, pos) == "]" then
                pos = pos + 1
                break
            end
            local val, new_pos = parse_value(str, pos)
            table.insert(arr, val)
            pos = skip_whitespace(str, new_pos)
            if str:sub(pos, pos) == "," then
                pos = pos + 1
            end
        end
        return arr, pos
    else
        return parse_number(str, pos)
    end
end

function json.decode(str)
    local val, pos = parse_value(str, 1)
    return val
end

return json