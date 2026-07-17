-- test/toml_parser_spec.lua
-- Test TOML parsing with the real toml.nvim library
-- Covers: strings, booleans, arrays, inline tables, nested sections,
--         dotted keys, array-of-tables, integers, comments

local lu = require('luaunit')
local toml = require('toml')

------------------------------------------------------------------
-- TestTomlBasicTypes: basic value types
------------------------------------------------------------------
TestTomlBasicTypes = {}

function TestTomlBasicTypes:test_parse_string()
  local result = toml.parse('key = "hello world"')
  lu.assertEquals(result.key, 'hello world')
end

function TestTomlBasicTypes:test_parse_single_quoted_string()
  local result = toml.parse("key = 'literal string'")
  lu.assertEquals(result.key, 'literal string')
end

function TestTomlBasicTypes:test_parse_boolean_true()
  local result = toml.parse('key = true')
  lu.assertEquals(result.key, true)
end

function TestTomlBasicTypes:test_parse_boolean_false()
  local result = toml.parse('key = false')
  lu.assertEquals(result.key, false)
end

function TestTomlBasicTypes:test_parse_integer()
  local result = toml.parse('key = 42')
  lu.assertEquals(result.key, 42)
end

function TestTomlBasicTypes:test_parse_negative_integer()
  local result = toml.parse('key = -17')
  lu.assertEquals(result.key, -17)
end

function TestTomlBasicTypes:test_parse_float()
  local result = toml.parse('key = 3.14')
  lu.assertEquals(result.key, 3.14)
end

------------------------------------------------------------------
-- TestTomlArrays: array parsing
------------------------------------------------------------------
TestTomlArrays = {}

function TestTomlArrays:test_parse_string_array()
  local result = toml.parse('key = ["a", "b", "c"]')
  lu.assertEquals(#result.key, 3)
  lu.assertEquals(result.key[1], 'a')
  lu.assertEquals(result.key[2], 'b')
  lu.assertEquals(result.key[3], 'c')
end

function TestTomlArrays:test_parse_mixed_type_array()
  local result = toml.parse('key = ["str", 42, true]')
  lu.assertEquals(result.key[1], 'str')
  lu.assertEquals(result.key[2], 42)
  lu.assertEquals(result.key[3], true)
end

function TestTomlArrays:test_parse_empty_array()
  local result = toml.parse('key = []')
  lu.assertEquals(#result.key, 0)
end

function TestTomlArrays:test_parse_single_element_array()
  local result = toml.parse('key = ["only"]')
  lu.assertEquals(#result.key, 1)
  lu.assertEquals(result.key[1], 'only')
end

------------------------------------------------------------------
-- TestTomlInlineTable: inline table parsing
------------------------------------------------------------------
TestTomlInlineTable = {}

function TestTomlInlineTable:test_parse_inline_table()
  local result = toml.parse('key = { a = "1", b = "2" }')
  lu.assertEquals(result.key.a, '1')
  lu.assertEquals(result.key.b, '2')
end

function TestTomlInlineTable:test_parse_inline_table_with_boolean()
  local result = toml.parse('key = { flag = true }')
  lu.assertTrue(result.key.flag)
end

function TestTomlInlineTable:test_parse_inline_table_with_integer()
  local result = toml.parse('key = { count = 5 }')
  lu.assertEquals(result.key.count, 5)
end

------------------------------------------------------------------
-- TestTomlSections: section headers and nested sections
------------------------------------------------------------------
TestTomlSections = {}

function TestTomlSections:test_parse_simple_section()
  local result = toml.parse('[server]\nhost = "localhost"\nport = 8080')
  lu.assertEquals(result.server.host, 'localhost')
  lu.assertEquals(result.server.port, 8080)
end

function TestTomlSections:test_parse_nested_section()
  local result = toml.parse('[server.options]\nhost = "localhost"\ntimeout = 30')
  lu.assertNotNil(result.server)
  lu.assertNotNil(result.server.options)
  lu.assertEquals(result.server.options.host, 'localhost')
  lu.assertEquals(result.server.options.timeout, 30)
end

function TestTomlSections:test_parse_multiple_sections()
  local toml_text = [=[
[section1]
key1 = "val1"

[section2]
key2 = "val2"
]=]
  local result = toml.parse(toml_text)
  lu.assertEquals(result.section1.key1, 'val1')
  lu.assertEquals(result.section2.key2, 'val2')
end

function TestTomlSections:test_parse_deeply_nested_section()
  local toml_text = [=[
[a.b.c]
key = "deep"
]=]
  local result = toml.parse(toml_text)
  lu.assertEquals(result.a.b.c.key, 'deep')
end

------------------------------------------------------------------
-- TestTomlDottedKeys: dotted key syntax at root level
------------------------------------------------------------------
TestTomlDottedKeys = {}

function TestTomlDottedKeys:test_parse_dotted_key()
  local result = toml.parse('a.b = "value"')
  lu.assertEquals(result.a.b, 'value')
end

function TestTomlDottedKeys:test_parse_deeply_dotted_key()
  local result = toml.parse('a.b.c = "deep"')
  lu.assertEquals(result.a.b.c, 'deep')
end

------------------------------------------------------------------
-- TestTomlArrayOfTables: [[name]] syntax
------------------------------------------------------------------
TestTomlArrayOfTables = {}

function TestTomlArrayOfTables:test_parse_array_of_tables()
  -- Use [=[ ]=] to avoid Lua long-string conflict with TOML [[ ]]
  local toml_text = [=[
[[products]]
name = "Hammer"
sku = 738594937

[[products]]
name = "Nail"
sku = 284758393
]=]
  local result = toml.parse(toml_text)
  lu.assertNotNil(result.products)
  lu.assertEquals(#result.products, 2)
  lu.assertEquals(result.products[1].name, 'Hammer')
  lu.assertEquals(result.products[1].sku, 738594937)
  lu.assertEquals(result.products[2].name, 'Nail')
  lu.assertEquals(result.products[2].sku, 284758393)
end

------------------------------------------------------------------
-- TestTomlComments: comment handling
------------------------------------------------------------------
TestTomlComments = {}

function TestTomlComments:test_parse_with_comment()
  local result = toml.parse('# this is a comment\nkey = "value"')
  lu.assertEquals(result.key, 'value')
end

function TestTomlComments:test_parse_inline_comment()
  local result = toml.parse('key = "value" # inline comment')
  lu.assertEquals(result.key, 'value')
end

function TestTomlComments:test_parse_comment_only()
  local result = toml.parse('# just a comment')
  -- Should return an empty table, not error
  lu.assertEquals(type(result), 'table')
end

------------------------------------------------------------------
-- TestTomlParseFile: file-based parsing
------------------------------------------------------------------
TestTomlParseFile = {}

function TestTomlParseFile:test_parse_file_reads_toml()
  -- Write a temp TOML file
  local tmp = vim.fn.tempname() .. '.toml'
  vim.fn.writefile({
    '[task]',
    'command = "echo hello"',
    'description = "Test task"',
  }, tmp)

  local result = toml.parse_file(tmp)
  lu.assertEquals(result.task.command, 'echo hello')
  lu.assertEquals(result.task.description, 'Test task')

  vim.fn.delete(tmp)
end

function TestTomlParseFile:test_parse_file_nonexistent_errors()
  local ok, _ = pcall(toml.parse_file, '/nonexistent/path/file.toml')
  lu.assertFalse(ok, 'Should error on nonexistent file')
end

------------------------------------------------------------------
-- TestTomlEdgeCases: edge cases and special characters
------------------------------------------------------------------
TestTomlEdgeCases = {}

function TestTomlEdgeCases:test_parse_empty_string()
  local result = toml.parse('key = ""')
  lu.assertEquals(result.key, '')
end

function TestTomlEdgeCases:test_parse_string_with_spaces()
  local result = toml.parse('key = "hello world with spaces"')
  lu.assertEquals(result.key, 'hello world with spaces')
end

function TestTomlEdgeCases:test_parse_string_with_special_chars()
  local result = toml.parse('key = "path/to/file.txt"')
  lu.assertEquals(result.key, 'path/to/file.txt')
end

function TestTomlEdgeCases:test_parse_empty_input()
  local result = toml.parse('')
  lu.assertEquals(type(result), 'table')
end

function TestTomlEdgeCases:test_parse_multiline_section()
  local toml_text = [=[
[build]
command = "make build"
description = "Build the project"
args = ["--verbose", "--jobs=4"]

[build.options]
cwd = "/project"
env = { DEBUG = "1" }
]=]
  local result = toml.parse(toml_text)
  lu.assertEquals(result.build.command, 'make build')
  lu.assertEquals(result.build.description, 'Build the project')
  lu.assertEquals(#result.build.args, 2)
  lu.assertEquals(result.build.args[1], '--verbose')
  lu.assertEquals(result.build.args[2], '--jobs=4')
  lu.assertEquals(result.build.options.cwd, '/project')
  lu.assertEquals(result.build.options.env.DEBUG, '1')
end

------------------------------------------------------------------
-- Run the test suite
------------------------------------------------------------------
-- Note: os.exit(lu.LuaUnit.run()) is intentionally NOT called here.
-- The test runner (test/run.lua) loads all test files and runs them
-- together via runner:runSuite().

