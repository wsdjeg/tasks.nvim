-- test/minimal_init.lua
-- Minimal Neovim configuration for testing tasks.nvim

print('Initializing test environment...')

-- Set up essential settings
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = false
vim.opt.verbose = 1

-- Set up package path for:
-- 1. lua/?.lua - Main plugin source code (tasks module)
-- 2. test/?.lua - Mock modules (toml.lua)
-- 3. test/.deps/?.lua - Test dependencies (luaunit)
package.path = 'lua/?.lua;test/?.lua;test/.deps/?.lua;' .. package.path
vim.opt.runtimepath:prepend('.')

-- Create temporary test directory with test TOML files
local test_dir = vim.fn.tempname() .. '_tasks_nvim_test'
vim.fn.mkdir(test_dir, 'p')

-- Write test global TOML file
local global_toml = test_dir .. '/global_tasks.toml'
vim.fn.writefile({
  '[test-global]',
  'command = "echo global"',
  'description = "Global test task"',
  '',
  '[lint]',
  'command = "luacheck ."',
  'description = "Run linter"',
}, global_toml)

-- Write test local TOML file
local local_toml = test_dir .. '/local_tasks.toml'
vim.fn.writefile({
  '[test-local]',
  'command = "echo local"',
  'description = "Local test task"',
  'args = ["--flag", "value"]',
  '',
  '[build]',
  'command = "make build"',
  'description = "Build project"',
  '',
  '[build.options]',
  'cwd = "${workspaceFolder}"',
}, local_toml)

-- Store test directory globally so test spec files can access it
-- NOTE: Global names must NOT start with "Test" or luaunit will pick them up
_G.TASKS_DIR = test_dir
_G.TASKS_GLOBAL_TOML = global_toml
_G.TASKS_LOCAL_TOML = local_toml

-- Load plugin with test configuration
local ok, err = pcall(function()
  require('tasks').setup({
    global_tasks = global_toml,
    local_tasks = local_toml,
  })
end)

if not ok then
  print('Error initializing test environment: ' .. err)
else
  print('Test environment initialized successfully')
  print('Test directory: ' .. test_dir)
end

