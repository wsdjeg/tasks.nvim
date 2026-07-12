-- test/toml.lua
-- Minimal TOML parser mock for testing tasks.nvim
-- Supports: section headers, nested sections ([a.b]), strings, booleans,
--           arrays, integers, and comments.

local M = {}

--- Parse a TOML string into a Lua table.
--- @param text string TOML content
--- @return table parsed result
function M.parse(text)
  local result = {}
  local current_section = result

  for line in text:gmatch('[^\r\n]+') do
    -- Strip comments (but not inside strings — simple approach)
    line = line:gsub('#.*$', '')
    -- Strip leading/trailing whitespace
    line = line:gsub('^%s+', ''):gsub('%s+$', '')

    if line == '' then
      -- skip empty lines
    elseif line:match('^%[(.+)%]$') then
      -- Section header: [name] or [name.subname]
      local section_path = line:match('^%[(.+)%]$')
      current_section = result
      for part in section_path:gmatch('[^.]+') do
        part = part:gsub('^%s+', ''):gsub('%s+$', '')
        if current_section[part] == nil then
          current_section[part] = {}
        end
        current_section = current_section[part]
      end
    else
      -- Key-value pair: key = value
      local key, value = line:match('^(%S-)%s*=%s*(.+)$')
      if key and value then
        value = value:gsub('^%s+', ''):gsub('%s+$', '')
        current_section[key] = M._parse_value(value)
      end
    end
  end

  return result
end

--- Parse a single TOML value string into its Lua equivalent.
--- @param value string raw value text
--- @return any parsed value
function M._parse_value(value)
  -- Double-quoted string
  if value:match('^"(.*)"$') then
    return value:match('^"(.*)"$')
  end

  -- Single-quoted (literal) string
  if value:match("^'(.*)'$") then
    return value:match("^'(.*)'$")
  end

  -- Boolean
  if value == 'true' then
    return true
  end
  if value == 'false' then
    return false
  end

  -- Array: ["a", "b", 1, true]
  if value:match('^%[') and value:match('%]$') then
    local arr = {}
    -- Extract string items
    for item in value:gmatch('"([^"]*)"') do
      table.insert(arr, item)
    end
    -- If no string items found, try bare values
    if #arr == 0 then
      local inner = value:match('^%[(.*)%]$')
      if inner and inner:match('%S') then
        for item in inner:gmatch('%s*([^,]+)%s*') do
          item = item:gsub('^%s+', ''):gsub('%s+$', '')
          if item ~= '' then
            table.insert(arr, M._parse_value(item))
          end
        end
      end
    end
    return arr
  end

  -- Inline table: { key = "value", key2 = true }
  if value:match('^{') and value:match('}$') then
    local tbl = {}
    local inner = value:match('^{%s*(.*)%s*}$')
    if inner then
      for k, v in inner:gmatch('%s*(%S-)%s*=%s*([^,]+)') do
        v = v:gsub('^%s+', ''):gsub('%s+$', '')
        tbl[k] = M._parse_value(v)
      end
    end
    return tbl
  end

  -- Number
  local num = tonumber(value)
  if num then
    return num
  end

  -- Fallback: return as raw string
  return value
end

--- Parse a TOML file from disk.
--- @param path string file path
--- @return table parsed result
function M.parse_file(path)
  local lines = vim.fn.readfile(path)
  local content = table.concat(lines, '\n')
  return M.parse(content)
end

return M

