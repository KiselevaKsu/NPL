-- INI → JSON

-- Парсим INI: возвращает таблицу {section = {key = value}}
local function parse_ini(text)
    local result = {}
    local current_section = nil

    for line in text:gmatch("[^\r\n]+") do
        -- убираем пробелы в начале и конце
        local trimmed = line:match("^%s*(.-)%s*$")

        -- пропускаем пустые строки и комментарии
        if trimmed ~= "" and not trimmed:match("^;") and not trimmed:match("^#") then
            -- секция
            local section = trimmed:match("^%[(.+)%]$")
            if section then
                current_section = section
                result[current_section] = result[current_section] or {}
            else
                -- пара key = value
                local key, value = trimmed:match("^([^=]+)%s*=%s*(.*)$")
                if key and value then
                    key = key:match("^%s*(.-)%s*$")
                    value = value:match("^%s*(.-)%s*$")
                    -- убираем кавычки, если есть
                    if value:match('^".*"$') or value:match("^'.*'$") then
                        value = value:sub(2, -2)
                    end
                    if current_section then
                        result[current_section][key] = value
                    else
                        -- ключи без секции идут в корень
                        result[key] = value
                    end
                end
            end
        end
    end

    return result
end

-- Экранируем строку для JSON
local function json_escape(s)
    s = s:gsub("\\", "\\\\")
    s = s:gsub('"', '\\"')
    s = s:gsub("\n", "\\n")
    s = s:gsub("\r", "\\r")
    s = s:gsub("\t", "\\t")
    return s
end

-- Преобразуем таблицу в JSON-строку с отступами
local function to_json(value, indent)
    indent = indent or 0
    local pad = string.rep("  ", indent)
    local pad_inner = string.rep("  ", indent + 1)
    local t = type(value)

    if t == "string" then
        -- если строка выглядит как число, выводим как строку (сохраняем как было)
        return '"' .. json_escape(value) .. '"'
    elseif t == "number" then
        return tostring(value)
    elseif t == "boolean" then
        return tostring(value)
    elseif t == "table" then
        -- проверяем, массив это или объект
        local is_array = true
        local max_index = 0
        for k, _ in pairs(value) do
            if type(k) ~= "number" then
                is_array = false
                break
            end
            if k > max_index then max_index = k end
        end
        if is_array and max_index > 0 then
            -- массив
            local parts = {}
            for i = 1, max_index do
                table.insert(parts, pad_inner .. to_json(value[i], indent + 1))
            end
            if #parts == 0 then return "[]" end
            return "[\n" .. table.concat(parts, ",\n") .. "\n" .. pad .. "]"
        else
            -- объект
            local keys = {}
            for k, _ in pairs(value) do
                table.insert(keys, k)
            end
            table.sort(keys)
            local parts = {}
            for _, k in ipairs(keys) do
                table.insert(parts,
                    pad_inner .. '"' .. json_escape(k) .. '": ' ..
                    to_json(value[k], indent + 1))
            end
            if #parts == 0 then return "{}" end
            return "{\n" .. table.concat(parts, ",\n") .. "\n" .. pad .. "}"
        end
    else
        return "null"
    end
end

-- main
local input_file = arg[1] or "input.ini"
local output_file = arg[2] or "output.json"

local f = assert(io.open(input_file, "r"))
local text = f:read("*a")
f:close()

local data = parse_ini(text)
local json = to_json(data)

local out = assert(io.open(output_file, "w"))
out:write(json)
out:write("\n")
out:close()

print("Input:  " .. input_file)
print("Output: " .. output_file)