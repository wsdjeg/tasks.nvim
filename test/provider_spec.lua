-- test/provider_spec.lua
-- Tests for provider system: registration, merge behavior, npm detection

local lu = require('luaunit')
local tasks = require('tasks')

------------------------------------------------------------------
-- TestProviderRegistration: basic provider registration
------------------------------------------------------------------
TestProviderRegistration = {}

function TestProviderRegistration:test_register_returns_task()
  tasks.reg_provider(function()
    return {
      ['provider-task-1'] = {
        command = 'echo provider1',
        description = 'Provider task 1',
      },
    }
  end)

  local result = tasks.get_tasks()
  lu.assertNotNil(result['provider-task-1'])
  lu.assertEquals(result['provider-task-1'].command, 'echo provider1')
end

function TestProviderRegistration:test_register_with_isDetected()
  tasks.reg_provider(function()
    return {
      ['detected-task'] = {
        command = 'npm test',
        isDetected = true,
        detectedName = 'npm: ',
      },
    }
  end)

  local result = tasks.get_tasks()
  lu.assertNotNil(result['detected-task'])
  lu.assertTrue(result['detected-task'].isDetected)
  lu.assertEquals(result['detected-task'].detectedName, 'npm: ')
end

function TestProviderRegistration:test_register_empty_provider()
  tasks.reg_provider(function()
    return {}
  end)

  local result = tasks.get_tasks()
  lu.assertEquals(type(result), 'table')
end

------------------------------------------------------------------
-- TestProviderMerge: multiple providers and merge behavior
------------------------------------------------------------------
TestProviderMerge = {}

function TestProviderMerge:test_multiple_providers()
  tasks.reg_provider(function()
    return {
      ['multi-a'] = { command = 'echo a' },
    }
  end)
  tasks.reg_provider(function()
    return {
      ['multi-b'] = { command = 'echo b' },
    }
  end)

  local result = tasks.get_tasks()
  lu.assertNotNil(result['multi-a'])
  lu.assertNotNil(result['multi-b'])
  lu.assertEquals(result['multi-a'].command, 'echo a')
  lu.assertEquals(result['multi-b'].command, 'echo b')
end

function TestProviderMerge:test_provider_merges_with_toml_tasks()
  -- TOML tasks should still be present alongside provider tasks
  tasks.reg_provider(function()
    return {
      ['provider-extra'] = { command = 'echo extra' },
    }
  end)

  local result = tasks.get_tasks()
  -- TOML tasks
  lu.assertNotNil(result['test-global'])
  lu.assertNotNil(result['test-local'])
  -- Provider task
  lu.assertNotNil(result['provider-extra'])
end

function TestProviderMerge:test_provider_does_not_override_toml()
  -- Provider tasks are merged with vim.tbl_deep_extend('force', ...)
  -- which means TOML tasks loaded first, then provider tasks force-merged
  -- A provider task with the same name as a TOML task should override it
  tasks.reg_provider(function()
    return {
      ['test-local'] = {
        command = 'echo overridden',
        isDetected = true,
      },
    }
  end)

  local result = tasks.get_tasks()
  lu.assertNotNil(result['test-local'])
  -- Provider should override TOML
  lu.assertEquals(result['test-local'].command, 'echo overridden')
end

------------------------------------------------------------------
-- TestNpmProvider: npm task auto-detection
------------------------------------------------------------------
TestNpmProvider = {}

function TestNpmProvider:test_npm_provider_function_exists()
  local npm = require('tasks.provider.npm')
  lu.assertEquals(type(npm), 'function')
end

function TestNpmProvider:test_npm_provider_no_package_json()
  -- Save current directory
  local old_cwd = vim.fn.getcwd()

  -- Create a temp directory without package.json
  local tmp_dir = vim.fn.tempname() .. '_no_npm'
  vim.fn.mkdir(tmp_dir, 'p')
  vim.cmd('cd ' .. tmp_dir)

  local npm = require('tasks.provider.npm')
  local result = npm()

  lu.assertEquals(type(result), 'table')
  lu.assertEquals(vim.tbl_count(result), 0, 'should return empty table without package.json')

  -- Restore and cleanup
  vim.cmd('cd ' .. old_cwd)
  vim.fn.delete(tmp_dir, 'rf')
end

function TestNpmProvider:test_npm_provider_with_package_json()
  -- Save current directory
  local old_cwd = vim.fn.getcwd()

  -- Create a temp directory with package.json
  local tmp_dir = vim.fn.tempname() .. '_with_npm'
  vim.fn.mkdir(tmp_dir, 'p')

  -- Write a minimal package.json with scripts
  local pkg_json = vim.fn.json_encode({
    name = 'test-pkg',
    scripts = {
      ['test'] = 'echo test',
      ['build'] = 'echo build',
      ['dev'] = 'echo dev',
    },
  })
  vim.fn.writefile({ pkg_json }, tmp_dir .. '/package.json')

  vim.cmd('cd ' .. tmp_dir)

  local npm = require('tasks.provider.npm')
  local result = npm()

  lu.assertNotNil(result['test'])
  lu.assertNotNil(result['build'])
  lu.assertNotNil(result['dev'])
  lu.assertTrue(result['test'].isDetected)
  lu.assertEquals(result['test'].detectedName, 'npm:')
  lu.assertEquals(result['test'].command, 'echo test')
  lu.assertEquals(result['build'].command, 'echo build')
  lu.assertEquals(result['dev'].command, 'echo dev')

  -- Restore and cleanup
  vim.cmd('cd ' .. old_cwd)
  vim.fn.delete(tmp_dir, 'rf')
end

function TestNpmProvider:test_npm_provider_empty_scripts()
  -- Save current directory
  local old_cwd = vim.fn.getcwd()

  local tmp_dir = vim.fn.tempname() .. '_empty_scripts'
  vim.fn.mkdir(tmp_dir, 'p')

  -- package.json without scripts
  local pkg_json = vim.fn.json_encode({
    name = 'no-scripts-pkg',
    version = '1.0.0',
  })
  vim.fn.writefile({ pkg_json }, tmp_dir .. '/package.json')

  vim.cmd('cd ' .. tmp_dir)

  local npm = require('tasks.provider.npm')
  local result = npm()

  lu.assertEquals(vim.tbl_count(result), 0, 'should return empty without scripts')

  -- Restore and cleanup
  vim.cmd('cd ' .. old_cwd)
  vim.fn.delete(tmp_dir, 'rf')
end

------------------------------------------------------------------
-- TestProviderInGetTasks: providers are called in get_tasks()
------------------------------------------------------------------
TestProviderInGetTasks = {}

function TestProviderInGetTasks:test_get_tasks_includes_provider_tasks()
  tasks.reg_provider(function()
    return {
      ['get-tasks-provider'] = {
        command = 'echo from-get-tasks',
        description = 'From provider in get_tasks',
      },
    }
  end)

  local result = tasks.get_tasks()
  lu.assertNotNil(result['get-tasks-provider'])
  lu.assertEquals(result['get-tasks-provider'].command, 'echo from-get-tasks')
end

function TestProviderInGetTasks:test_provider_called_each_time()
  local call_count = 0
  tasks.reg_provider(function()
    call_count = call_count + 1
    return {
      ['counted-task'] = { command = 'echo count ' .. call_count },
    }
  end)

  local result1 = tasks.get_tasks()
  local result2 = tasks.get_tasks()

  -- Provider should be called each time get_tasks is called
  lu.assertTrue(call_count >= 2, 'provider should be called at least twice')
end

------------------------------------------------------------------
-- Run the test suite
------------------------------------------------------------------
-- Note: os.exit(lu.LuaUnit.run()) is intentionally NOT called here.
-- The test runner (test/run.lua) loads all test files and runs them
-- together via runner:runSuite().

