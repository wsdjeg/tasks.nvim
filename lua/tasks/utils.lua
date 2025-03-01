local M = {}

local is_win = vim.fn.has('win32') == 1
M.unify_path = function(_path, ...)
  local mod = select(1, ...)
  if mod == nil then
    mod = ':p'
  end
  local path = vim.fn.fnamemodify(_path, mod .. ':gs?[\\\\/]?/?')
  if is_win then
    local re = vim.regex('^[a-zA-Z]:/')
    if re:match_str(path) then
      path = string.upper(string.sub(path, 1, 1)) .. string.sub(path, 2)
    end
  end
  if vim.fn.isdirectory(path) == 1 and string.sub(path, -1) ~= '/' then
    return path .. '/'
  elseif string.sub(_path, -1) == '/' and string.sub(path, -1) ~= '/' then
    return path .. '/'
  else
    return path
  end
end

local function has(o)
  return vim.fn.has(o) == 1
end

if has('win16') == 1 or has('win32') == 1 or has('win64') == 1 then
  M.isWindows = true
else
  M.isWindows = false
end
if has('unix') == 1 and has('macunix') == 0 and has('win32unix') == 0 then
  M.isLinux = true
else
  M.isLinux = false
end
M.isOSX = has('macunix')
local function getchar(...)
  local status, ret = pcall(vim.fn.getchar, ...)
  if not status then
    ret = 3
  end
  if type(ret) == 'number' then
    return vim.fn.nr2char(ret)
  else
    return ret
  end
end

local Key = {}
function Key.t(str)
  if vim.api ~= nil and vim.api.nvim_replace_termcodes ~= nil then
    -- https://github.com/neovim/neovim/issues/17369
    local ret = vim.api.nvim_replace_termcodes(str, false, true, true):gsub('\128\254X', '\128')
    return ret
  else
    -- local ret = vim.fn.execute('echon "\\' .. str .. '"')
    -- ret = ret:gsub('<80>', '\128')
    -- return ret
    return vim.eval(string.format('"\\%s"', str))
  end
end

local function echo(str)
  vim.api.nvim_echo({ { str, 'Normal' } }, false, {})
end

local function next_item(list, item)
  local id = vim.fn.index(list, item)
  if id == #list - 1 then
    return list[1]
  else
    return list[id + 2]
  end
end

local function previous_item(list, item)
  local id = vim.fn.index(list, item)
  if id == 0 then
    return list[#list]
  else
    return list[id]
  end
end

local function parse_items(items)
  local is = {}
  local id = 1
  for _, item in ipairs(items) do
    is[id] = item
    is[id][1] = '(' .. id .. ')' .. item[1]
    id = id + 1
  end
  return is
end

local function list_keys(l)
  if #l == 0 then
    return {}
  end
  return vim.fn.range(1, #l)
end

function M.menu(items)
  local cancelled = false
  local saved_more = vim.o.more
  local saved_cmdheight = vim.o.cmdheight
  vim.o.more = false
  items = parse_items(items)
  vim.o.cmdheight = #items + 1
  vim.cmd('redrawstatus!')
  local selected = 1
  local exit = false
  local indent = string.rep(' ', 7, '')
  while not exit do
    local menu = 'Cmdline menu: Use j/k/enter and the shortcuts indicated\n'
    local id = 1
    for _, _ in pairs(items) do
      if id == selected then
        menu = menu .. indent .. '>' .. items[id][1] .. '\n'
      else
        menu = menu .. indent .. ' ' .. items[id][1] .. '\n'
      end
      id = id + 1
    end

    vim.cmd('redraw!')
    echo(string.sub(menu, 1, #menu - 1))
    local char = getchar()
    if char == Key.t('<Esc>') or char == Key.t('<C-c>') then
      exit = true
      cancelled = true
      vim.cmd('normal! :')
    elseif vim.fn.index(list_keys(items), tonumber(char)) ~= -1 or char == Key.t('<Cr>') then
      if char ~= Key.t('<Cr>') then
        selected = tonumber(char, 10)
      end
      local value = items[selected][2]
      vim.cmd('normal! :')
      if type(value) == 'function' then
        local args = items[selected][3] or {}
        local ok, err = pcall(value, unpack(args))
        if not ok then
          print(err)
        end
      elseif type(value) == 'string' then
        vim.cmd(value)
      end
      exit = true
    elseif char == 'j' or char == Key.t('<Tab>') then
      selected = next_item(list_keys(items), selected)
      vim.cmd('normal! :')
    elseif char == 'k' or char == Key.t('<S-Tab>') then
      selected = previous_item(list_keys(items), selected)
      vim.cmd('normal! :')
    else
      vim.cmd('normal! :')
    end
  end
  vim.o.more = saved_more
  vim.o.cmdheight = saved_cmdheight
  vim.cmd('redraw!')
  if cancelled then
    echo('cancelled!')
  end
end

return M
