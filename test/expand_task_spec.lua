-- test/expand_task_spec.lua
-- Comprehensive tests for expand_task: variable expansion, OS overrides,
-- options.cwd, options.env, args expansion

local lu = require('luaunit')
local tasks = require('tasks')

------------------------------------------------------------------
-- TestExpandBasic: basic variable expansion in command
------------------------------------------------------------------
TestExpandBasic = {}

function TestExpandBasic:test_expand_no_variables()
  local task = { command = 'echo hello' }
  local expanded = tasks.expand_task(task)
  lu.assertEquals(expanded.command, 'echo hello')
end

function TestExpandBasic:test_expand_workspace_folder()
  local task = { command = 'echo ${workspaceFolder}' }
  local expanded = tasks.expand_task(task)
  lu.assertNotEquals(expanded.command, 'echo ${workspaceFolder}')
  -- Should start with 'echo '
  lu.assertNotNil(expanded.command:find('^echo '), 'should start with echo')
end

function TestExpandBasic:test_expand_workspace_folder_basename()
  local task = { command = 'echo ${workspaceFolderBasename}' }
  local expanded = tasks.expand_task(task)
  lu.assertNotEquals(expanded.command, 'echo ${workspaceFolderBasename}')
  -- basename should not contain path separators
  lu.assertNil(expanded.command:find('/', 1, true), 'basename should not have /')
end

function TestExpandBasic:test_expand_multiple_variables()
  local task = { command = 'echo ${workspaceFolder} ${workspaceFolderBasename}' }
  local expanded = tasks.expand_task(task)
  -- Use plain find to check for unresolved ${...} patterns
  lu.assertNil(expanded.command:find('${', 1, true), 'no unresolved variables')
end

function TestExpandBasic:test_expand_file_variables()
  local task = {
    command = 'echo ${file} ${fileBasename} ${fileExtname}',
  }
  local expanded = tasks.expand_task(task)
  lu.assertNil(expanded.command:find('${', 1, true), 'no unresolved variables')
end

function TestExpandBasic:test_expand_line_number()
  local task = { command = 'echo line ${lineNumber}' }
  local expanded = tasks.expand_task(task)
  lu.assertNil(expanded.command:find('${lineNumber}', 1, true), 'lineNumber should be expanded')
  -- lineNumber should be a number string
  lu.assertNotNil(expanded.command:find('line %d+$'), 'should end with a number')
end

------------------------------------------------------------------
-- TestExpandArgs: variable expansion in args array
------------------------------------------------------------------
TestExpandArgs = {}

function TestExpandArgs:test_expand_args_with_variable()
  local task = {
    command = 'echo',
    args = { '${workspaceFolderBasename}' },
  }
  local expanded = tasks.expand_task(task)
  lu.assertNotEquals(expanded.args[1], '${workspaceFolderBasename}')
end

function TestExpandArgs:test_expand_args_mixed()
  local task = {
    command = 'echo',
    args = { '${workspaceFolder}', 'static', '${fileBasename}' },
  }
  local expanded = tasks.expand_task(task)
  lu.assertNotEquals(expanded.args[1], '${workspaceFolder}')
  lu.assertEquals(expanded.args[2], 'static')
  lu.assertNotEquals(expanded.args[3], '${fileBasename}')
end

function TestExpandArgs:test_expand_no_args()
  local task = { command = 'echo hello' }
  local expanded = tasks.expand_task(task)
  lu.assertNil(expanded.args)
end

function TestExpandArgs:test_expand_empty_args()
  local task = { command = 'echo', args = {} }
  local expanded = tasks.expand_task(task)
  lu.assertEquals(type(expanded.args), 'table')
  lu.assertEquals(#expanded.args, 0)
end

------------------------------------------------------------------
-- TestExpandOptions: options.cwd and options.env
------------------------------------------------------------------
TestExpandOptions = {}

function TestExpandOptions:test_expand_cwd_variable()
  local task = {
    command = 'make build',
    options = { cwd = '${workspaceFolder}' },
  }
  local expanded = tasks.expand_task(task)
  lu.assertNotEquals(expanded.options.cwd, '${workspaceFolder}')
  lu.assertTrue(#expanded.options.cwd > 0, 'cwd should be non-empty')
end

function TestExpandOptions:test_expand_cwd_no_variable()
  local task = {
    command = 'make build',
    options = { cwd = '/fixed/path' },
  }
  local expanded = tasks.expand_task(task)
  lu.assertEquals(expanded.options.cwd, '/fixed/path')
end

function TestExpandOptions:test_expand_preserves_env()
  local task = {
    command = 'make build',
    options = { env = { KEY = 'value', FLAG = 'true' } },
  }
  local expanded = tasks.expand_task(task)
  lu.assertEquals(expanded.options.env.KEY, 'value')
  lu.assertEquals(expanded.options.env.FLAG, 'true')
end

function TestExpandOptions:test_expand_no_options()
  local task = { command = 'echo hello' }
  local expanded = tasks.expand_task(task)
  lu.assertNil(expanded.options)
end

------------------------------------------------------------------
-- TestExpandOSOverrides: OS-specific task overrides
------------------------------------------------------------------
TestExpandOSOverrides = {}

function TestExpandOSOverrides:test_os_override_applied()
  -- Depending on the OS, the override should be applied
  local task = {
    command = 'echo default',
    linux = { command = 'echo linux' },
    windows = { command = 'echo windows' },
    osx = { command = 'echo osx' },
  }
  local expanded = tasks.expand_task(task)
  -- The command should be one of the OS-specific ones (or default if none match)
  local cmds = { 'echo default', 'echo linux', 'echo windows', 'echo osx' }
  local found = false
  for _, c in ipairs(cmds) do
    if expanded.command == c then
      found = true
      break
    end
  end
  lu.assertTrue(found, 'command should match one of the OS variants')
end

function TestExpandOSOverrides:test_no_os_override_uses_default()
  local task = { command = 'echo default' }
  local expanded = tasks.expand_task(task)
  lu.assertEquals(expanded.command, 'echo default')
end

function TestExpandOSOverrides:test_os_override_with_args()
  local task = {
    command = 'echo default',
    args = { 'default-arg' },
    linux = {
      command = 'echo linux',
      args = { 'linux-arg' },
    },
  }
  local expanded = tasks.expand_task(task)
  -- If on Linux, should have linux command and args
  -- If not, should have default command and args
  if expanded.command == 'echo linux' then
    lu.assertEquals(expanded.args[1], 'linux-arg')
  else
    lu.assertEquals(expanded.command, 'echo default')
    lu.assertEquals(expanded.args[1], 'default-arg')
  end
end

------------------------------------------------------------------
-- TestExpandFromConfig: expand tasks loaded from TOML config
------------------------------------------------------------------
TestExpandFromConfig = {}

function TestExpandFromConfig:test_expand_build_task_cwd()
  local all_tasks = tasks.get_tasks()
  lu.assertNotNil(all_tasks['build'])
  lu.assertNotNil(all_tasks['build'].options)
  lu.assertNotNil(all_tasks['build'].options.cwd)

  local expanded = tasks.expand_task(all_tasks['build'])
  -- ${workspaceFolder} should be replaced (plain text search for ${)
  lu.assertNil(expanded.options.cwd:find('${workspaceFolder}', 1, true), 'cwd should be expanded')
end

function TestExpandFromConfig:test_expand_check_task()
  local all_tasks = tasks.get_tasks()
  lu.assertNotNil(all_tasks['check'])
  lu.assertNotNil(all_tasks['check'].options)
  lu.assertNotNil(all_tasks['check'].options.cwd)

  local expanded = tasks.expand_task(all_tasks['check'])
  lu.assertNil(expanded.options.cwd:find('${workspaceFolder}', 1, true), 'cwd should be expanded')
  -- env should be preserved
  lu.assertNotNil(expanded.options.env)
  lu.assertEquals(expanded.options.env.LUA_PATH, './?.lua')
  lu.assertEquals(expanded.options.env.LUA_CPATH, './?.so')
end

function TestExpandFromConfig:test_expand_clean_task_args()
  local all_tasks = tasks.get_tasks()
  lu.assertNotNil(all_tasks['clean'])
  lu.assertNotNil(all_tasks['clean'].args)

  local expanded = tasks.expand_task(all_tasks['clean'])
  lu.assertEquals(#expanded.args, 2)
  lu.assertEquals(expanded.args[1], '--force')
  lu.assertEquals(expanded.args[2], '--verbose')
end

function TestExpandFromConfig:test_expand_deploy_task_env()
  local all_tasks = tasks.get_tasks()
  lu.assertNotNil(all_tasks['deploy'])
  lu.assertNotNil(all_tasks['deploy'].options)
  lu.assertNotNil(all_tasks['deploy'].options.env)

  local expanded = tasks.expand_task(all_tasks['deploy'])
  lu.assertEquals(expanded.options.env.RSYNC_RSH, 'ssh -p 2222')
end

------------------------------------------------------------------
-- TestExpandIdempotency: expanding an already-expanded task
------------------------------------------------------------------
TestExpandIdempotency = {}

function TestExpandIdempotency:test_expand_static_task_unchanged()
  local task = {
    command = 'echo hello',
    args = { 'arg1', 'arg2' },
  }
  local expanded1 = tasks.expand_task(task)
  local expanded2 = tasks.expand_task(expanded1)
  lu.assertEquals(expanded2.command, expanded1.command)
end

function TestExpandIdempotency:test_expand_no_command()
  local task = { description = 'task without command' }
  local expanded = tasks.expand_task(task)
  lu.assertEquals(expanded.description, 'task without command')
  lu.assertNil(expanded.command)
end

------------------------------------------------------------------
-- Run the test suite
------------------------------------------------------------------
-- Note: os.exit(lu.LuaUnit.run()) is intentionally NOT called here.
-- The test runner (test/run.lua) loads all test files and runs them
-- together via runner:runSuite().

