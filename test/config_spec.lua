-- test/config_spec.lua
-- Tests for config module: defaults, overrides, provider initialization

local lu = require('luaunit')
local config = require('tasks.config')
local tasks = require('tasks')

------------------------------------------------------------------
-- TestConfigDefaults: default configuration values
------------------------------------------------------------------
TestConfigDefaults = {}

function TestConfigDefaults:test_global_tasks_default()
  -- Before setup, default is '~/.tasks.toml'
  -- After setup (in minimal_init.lua), it should be the test path
  -- We can verify it's a string
  lu.assertEquals(type(config.global_tasks), 'string')
  lu.assertTrue(#config.global_tasks > 0, 'global_tasks should be non-empty')
end

function TestConfigDefaults:test_local_tasks_default()
  lu.assertEquals(type(config.local_tasks), 'string')
  lu.assertTrue(#config.local_tasks > 0, 'local_tasks should be non-empty')
end

function TestConfigDefaults:test_provider_list_exists()
  lu.assertNotNil(config.provider)
  lu.assertEquals(type(config.provider), 'table')
  lu.assertTrue(#config.provider >= 1, 'should have at least one provider')
end

function TestConfigDefaults:test_provider_list_includes_npm()
  local has_npm = false
  for _, p in ipairs(config.provider) do
    if p == 'npm' then
      has_npm = true
      break
    end
  end
  lu.assertTrue(has_npm, 'npm should be in provider list')
end

------------------------------------------------------------------
-- TestConfigSetup: setup() with custom options
------------------------------------------------------------------
TestConfigSetup = {}

function TestConfigSetup:test_setup_sets_global_tasks()
  local custom_path = '/custom/global.toml'
  config.setup({ global_tasks = custom_path })
  lu.assertEquals(config.global_tasks, custom_path)
  -- Restore test config
  config.setup({
    global_tasks = _G.TASKS_GLOBAL_TOML,
    local_tasks = _G.TASKS_LOCAL_TOML,
  })
end

function TestConfigSetup:test_setup_sets_local_tasks()
  local custom_path = '/custom/local.toml'
  config.setup({ local_tasks = custom_path })
  lu.assertEquals(config.local_tasks, custom_path)
  -- Restore test config
  config.setup({
    global_tasks = _G.TASKS_GLOBAL_TOML,
    local_tasks = _G.TASKS_LOCAL_TOML,
  })
end

function TestConfigSetup:test_setup_preserves_defaults_when_nil()
  config.setup({})
  -- Should keep existing values (not reset to defaults)
  lu.assertEquals(config.global_tasks, _G.TASKS_GLOBAL_TOML)
  lu.assertEquals(config.local_tasks, _G.TASKS_LOCAL_TOML)
end

function TestConfigSetup:test_setup_with_empty_table()
  -- Should not throw
  local ok, err = pcall(function()
    config.setup({})
  end)
  lu.assertTrue(ok, 'setup({}) should not throw: ' .. tostring(err))
end

function TestConfigSetup:test_setup_with_nil()
  -- tasks.setup handles nil with `opt or {}`, but config.setup does not.
  -- Test through tasks.setup which is the public API.
  local ok, err = pcall(function()
    tasks.setup(nil)
  end)
  lu.assertTrue(ok, 'tasks.setup(nil) should not throw: ' .. tostring(err))
end

------------------------------------------------------------------
-- TestConfigProviderInit: provider initialization in setup
------------------------------------------------------------------
TestConfigProviderInit = {}

function TestConfigProviderInit:test_setup_loads_npm_provider()
  -- After setup, npm provider should be registered
  -- We can verify by checking if get_tasks includes npm-detected tasks
  -- when a package.json exists (tested in provider_spec.lua)
  -- Here we just verify the provider module is loadable
  local ok, npm = pcall(require, 'tasks.provider.npm')
  lu.assertTrue(ok, 'npm provider should be loadable')
  lu.assertEquals(type(npm), 'function')
end

function TestConfigProviderInit:test_setup_does_not_throw_with_unknown_provider()
  -- If a provider in the list doesn't exist, pcall should catch it
  -- The config.setup uses pcall internally for each provider
  -- Add an unknown provider and verify it doesn't crash
  local saved_provider = config.provider
  config.provider = { 'npm', 'nonexistent' }
  local ok, err = pcall(function()
    config.setup({})
  end)
  lu.assertTrue(ok, 'setup with unknown provider should not throw: ' .. tostring(err))
  -- Restore
  config.provider = saved_provider
  config.setup({
    global_tasks = _G.TASKS_GLOBAL_TOML,
    local_tasks = _G.TASKS_LOCAL_TOML,
  })
end

------------------------------------------------------------------
-- TestConfigReflectsTestSetup: config matches minimal_init.lua setup
------------------------------------------------------------------
TestConfigReflectsTestSetup = {}

function TestConfigReflectsTestSetup:test_global_tasks_matches_test_fixture()
  lu.assertEquals(config.global_tasks, _G.TASKS_GLOBAL_TOML)
end

function TestConfigReflectsTestSetup:test_local_tasks_matches_test_fixture()
  lu.assertEquals(config.local_tasks, _G.TASKS_LOCAL_TOML)
end

------------------------------------------------------------------
-- Run the test suite
------------------------------------------------------------------
-- Note: os.exit(lu.LuaUnit.run()) is intentionally NOT called here.
-- The test runner (test/run.lua) loads all test files and runs them
-- together via runner:runSuite(). Calling os.exit here would prevent
-- subsequent test files from being loaded.

