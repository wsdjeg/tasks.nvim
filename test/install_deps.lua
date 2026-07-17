-- test/install_deps.lua
-- Cross-platform test dependency installer
-- Replaces shell-based makefile targets (if [ ... ]; then ... fi doesn't work on Windows)

local function mkdir(path)
  vim.fn.mkdir(path, 'p')
end

local function file_exists(path)
  return vim.fn.filereadable(path) == 1
end

local function download(url, dest)
  -- Use curl if available (Linux, macOS, modern Windows)
  if vim.fn.executable('curl') == 1 then
    local cmd = { 'curl', '-fsSL', url, '-o', dest }
    vim.fn.system(cmd)
    return vim.v.shell_error == 0
  end

  -- Fallback: try powershell on Windows
  if vim.fn.has('win32') == 1 then
    local ps_cmd = string.format(
      "Invoke-WebRequest -Uri '%s' -OutFile '%s'",
      url, dest
    )
    vim.fn.system({ 'powershell', '-Command', ps_cmd })
    return vim.v.shell_error == 0
  end

  -- Fallback: try wget
  if vim.fn.executable('wget') == 1 then
    local cmd = { 'wget', '-q', url, '-O', dest }
    vim.fn.system(cmd)
    return vim.v.shell_error == 0
  end

  return false
end

local deps_dir = 'test/.deps'
mkdir(deps_dir)

-- Install luaunit
local luaunit_path = deps_dir .. '/luaunit.lua'
local luaunit_url = 'https://raw.githubusercontent.com/bluebird75/luaunit/main/luaunit.lua'

if file_exists(luaunit_path) then
  print('luaunit already installed')
else
  print('Installing luaunit...')
  if download(luaunit_url, luaunit_path) then
    print('luaunit installed to ' .. luaunit_path)
  else
    print('[ERROR] Failed to download luaunit')
    os.exit(1)
  end
end

-- Install toml.nvim (single-file, self-contained TOML parser)
-- Source: https://github.com/wsdjeg/toml.nvim/blob/master/lua/toml/init.lua
-- Downloaded as test/.deps/toml.lua so require('toml') finds it
local toml_path = deps_dir .. '/toml.lua'
local toml_url = 'https://raw.githubusercontent.com/wsdjeg/toml.nvim/master/lua/toml/init.lua'

if file_exists(toml_path) then
  print('toml.nvim already installed')
else
  print('Installing toml.nvim...')
  if download(toml_url, toml_path) then
    print('toml.nvim installed to ' .. toml_path)
  else
    print('[ERROR] Failed to download toml.nvim')
    os.exit(1)
  end
end

print('All dependencies installed.')
os.exit(0)

