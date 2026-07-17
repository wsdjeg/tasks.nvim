-- test/utils_spec.lua
-- Tests for tasks.utils module: unify_path, OS detection

local lu = require('luaunit')
local util = require('tasks.utils')

------------------------------------------------------------------
-- TestUtilsPath: unify_path function
------------------------------------------------------------------
TestUtilsPath = {}

function TestUtilsPath:test_unify_path_default_modifier()
  local result = util.unify_path('/tmp/test')
  lu.assertEquals(type(result), 'string')
  lu.assertTrue(#result > 0, 'path should be non-empty')
end

function TestUtilsPath:test_unify_path_explicit_p()
  local result = util.unify_path('/tmp/test', ':p')
  lu.assertEquals(type(result), 'string')
end

function TestUtilsPath:test_unify_path_basename()
  local result = util.unify_path('/tmp/testfile.xyz', ':t')
  lu.assertEquals(result, 'testfile.xyz')
end

function TestUtilsPath:test_unify_path_extension_unique()
  -- Use an extension that won't match a directory name in cwd
  local result = util.unify_path('/tmp/test.zzzuniq', ':e')
  -- unify_path may add trailing slash if a dir with that name exists,
  -- so just check the result starts with the extension
  lu.assertNotNil(result:find('^zzzuniq'), 'should start with extension name')
end

function TestUtilsPath:test_unify_path_dirname()
  local result = util.unify_path('/tmp/testfile.xyz', ':h')
  -- Should contain the directory path
  lu.assertNotNil(result:find('tmp', 1, true), 'should contain tmp')
end

function TestUtilsPath:test_unify_path_no_extension()
  local result = util.unify_path('/tmp/Makefile', ':e')
  -- No extension should return empty string (possibly with trailing slash)
  lu.assertTrue(result == '' or result == '/', 'no extension should be empty or /')
end

function TestUtilsPath:test_unify_path_trailing_slash_dir()
  -- Directories should get trailing slash
  local tmp_dir = vim.fn.tempname()
  vim.fn.mkdir(tmp_dir, 'p')
  local result = util.unify_path(tmp_dir)
  lu.assertTrue(result:sub(-1) == '/', 'directory should end with /')
  vim.fn.delete(tmp_dir, 'rf')
end

function TestUtilsPath:test_unify_path_relative_to_absolute()
  local result = util.unify_path('./test', ':p')
  -- Should be an absolute path:
  --   Unix: starts with /
  --   Windows: starts with drive letter, e.g. C:/
  local is_absolute = result:match('^/') ~= nil or result:match('^[a-zA-Z]:/') ~= nil
  lu.assertTrue(is_absolute, 'should be absolute path, got: ' .. result)
end

------------------------------------------------------------------
-- TestUtilsOS: OS detection flags
------------------------------------------------------------------
TestUtilsOS = {}

function TestUtilsOS:test_isWindows_is_boolean()
  lu.assertEquals(type(util.isWindows), 'boolean')
end

function TestUtilsOS:test_isLinux_is_boolean()
  lu.assertEquals(type(util.isLinux), 'boolean')
end

function TestUtilsOS:test_isOSX_value_exists()
  -- isOSX may be boolean or number (0/1) depending on has() return
  lu.assertNotNil(util.isOSX)
end

function TestUtilsOS:test_os_flags_mutually_exclusive()
  -- At most one OS should be truthy (Windows and Linux are booleans,
  -- OSX may be 0/1 number)
  local win_truthy = util.isWindows == true
  local linux_truthy = util.isLinux == true
  local osx_truthy = util.isOSX == true or util.isOSX == 1

  -- At most one should be true
  local count = 0
  if win_truthy then
    count = count + 1
  end
  if linux_truthy then
    count = count + 1
  end
  if osx_truthy then
    count = count + 1
  end
  lu.assertTrue(count <= 1, 'at most one OS should be truthy, got ' .. count)
end

------------------------------------------------------------------
-- Run the test suite
------------------------------------------------------------------
-- Note: os.exit(lu.LuaUnit.run()) is intentionally NOT called here.
-- The test runner (test/run.lua) loads all test files and runs them
-- together via runner:runSuite().

