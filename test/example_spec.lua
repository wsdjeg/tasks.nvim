-- test/example_spec.lua
-- Example test suite for tasks.nvim using luaunit
--
-- Run all tests:    make test
-- Run this file:    make test PATTERN=example
-- Run a single test: make test PATTERN=example (matches by file name)

local lu = require('luaunit')
local tasks = require('tasks')
local config = require('tasks.config')

-- Helper: get the tasks module fresh (it's cached by require, so this
-- returns the same instance that was set up in minimal_init.lua)

------------------------------------------------------------------
-- TestModuleLoading: verify the module loads and exposes API
------------------------------------------------------------------
TestModuleLoading = {}

function TestModuleLoading:test_module_requires()
  -- The module should be a table
  lu.assertEquals(type(tasks), 'table')
end

function TestModuleLoading:test_exports_key_functions()
  lu.assertNotNil(tasks.setup)
  lu.assertNotNil(tasks.get)
  lu.assertNotNil(tasks.list)
  lu.assertNotNil(tasks.edit)
  lu.assertNotNil(tasks.get_tasks)
  lu.assertNotNil(tasks.expand_task)
  lu.assertNotNil(tasks.reg_provider)
end

function TestModuleLoading:test_setup_accepts_config()
  -- setup should not throw
  local ok, err = pcall(function()
    tasks.setup({
      global_tasks = _G.TASKS_GLOBAL_TOML,
      local_tasks = _G.TASKS_LOCAL_TOML,
    })
  end)
  lu.assertTrue(ok, 'setup() should not throw: ' .. tostring(err))
end

------------------------------------------------------------------
-- TestGetTasks: verify get_tasks() reads TOML config files
------------------------------------------------------------------
TestGetTasks = {}

function TestGetTasks:test_returns_table()
  local result = tasks.get_tasks()
  lu.assertEquals(type(result), 'table')
end

function TestGetTasks:test_includes_global_tasks()
  local result = tasks.get_tasks()
  lu.assertNotNil(result['test-global'])
  lu.assertEquals(result['test-global'].command, 'echo global')
  lu.assertEquals(result['test-global'].description, 'Global test task')
end

function TestGetTasks:test_includes_local_tasks()
  local result = tasks.get_tasks()
  lu.assertNotNil(result['test-local'])
  lu.assertEquals(result['test-local'].command, 'echo local')
  lu.assertEquals(result['test-local'].description, 'Local test task')
end

function TestGetTasks:test_local_task_has_args()
  local result = tasks.get_tasks()
  lu.assertNotNil(result['test-local'].args)
  lu.assertEquals(#result['test-local'].args, 2)
  lu.assertEquals(result['test-local'].args[1], '--flag')
  lu.assertEquals(result['test-local'].args[2], 'value')
end

function TestGetTasks:test_local_overrides_global()
  -- Both global and local tasks should be present
  local result = tasks.get_tasks()
  lu.assertNotNil(result['test-global'])
  lu.assertNotNil(result['test-local'])
  lu.assertNotNil(result['build'])
  lu.assertNotNil(result['lint'])
end

------------------------------------------------------------------
-- TestExpandTask: verify variable expansion
------------------------------------------------------------------
TestExpandTask = {}

function TestExpandTask:test_expand_simple_command()
  local task = {
    command = 'echo hello',
  }
  local expanded = tasks.expand_task(task)
  lu.assertEquals(expanded.command, 'echo hello')
end

function TestExpandTask:test_expand_variables_in_command()
  local task = {
    command = 'echo ${workspaceFolder}',
  }
  local expanded = tasks.expand_task(task)
  -- ${workspaceFolder} should be replaced with the current working directory
  lu.assertNotEquals(expanded.command, 'echo ${workspaceFolder}')
  lu.assertNotNil(expanded.command:match('^echo '), 'command should still start with echo')
end

function TestExpandTask:test_expand_variables_in_args()
  local task = {
    command = 'echo',
    args = { '${workspaceFolderBasename}', 'static-arg' },
  }
  local expanded = tasks.expand_task(task)
  lu.assertEquals(expanded.args[2], 'static-arg')
  -- First arg should have the variable replaced
  lu.assertNotEquals(expanded.args[1], '${workspaceFolderBasename}')
end

function TestExpandTask:test_expand_preserves_static_args()
  local task = {
    command = 'make',
    args = { 'build', '--verbose' },
  }
  local expanded = tasks.expand_task(task)
  lu.assertEquals(expanded.command, 'make')
  lu.assertEquals(expanded.args[1], 'build')
  lu.assertEquals(expanded.args[2], '--verbose')
end

------------------------------------------------------------------
-- TestRegProvider: verify custom provider registration
------------------------------------------------------------------
TestRegProvider = {}

function TestRegProvider:test_register_custom_provider()
  -- Register a custom provider that returns a task
  tasks.reg_provider(function()
    return {
      ['custom-task'] = {
        command = 'echo custom',
        description = 'Custom provider task',
        isDetected = true,
        detectedName = 'custom:',
      },
    }
  end)

  local result = tasks.get_tasks()
  lu.assertNotNil(result['custom-task'])
  lu.assertEquals(result['custom-task'].command, 'echo custom')
  lu.assertEquals(result['custom-task'].description, 'Custom provider task')
  lu.assertTrue(result['custom-task'].isDetected)
end

------------------------------------------------------------------
-- TestConfig: verify config defaults and overrides
------------------------------------------------------------------
TestConfig = {}

function TestConfig:test_default_global_tasks()
  -- After setup with custom paths, config should reflect them
  lu.assertEquals(config.global_tasks, _G.TASKS_GLOBAL_TOML)
  lu.assertEquals(config.local_tasks, _G.TASKS_LOCAL_TOML)
end

function TestConfig:test_provider_list()
  lu.assertNotNil(config.provider)
  lu.assertTrue(type(config.provider) == 'table')
  lu.assertTrue(#config.provider >= 1)
end

------------------------------------------------------------------
-- Run the test suite
------------------------------------------------------------------
os.exit(lu.LuaUnit.run())

