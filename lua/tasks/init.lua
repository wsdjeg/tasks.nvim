--=============================================================================
-- tasks.lua
-- Copyright (c) 2016-2022 Wang Shidong & Contributors
-- Author: Wang Shidong < wsdjeg@outlook.com >
-- License: GPLv3
--=============================================================================

local M = {}

local selected_task = {}

local task_config = {}

local task_viewer_bufnr = -1

local variables = {}

local providers = {}

-- load apis

local util = require('tasks.utils')
local toml = require('tasks.toml')
local log = require('tasks.logger')
local config = require('tasks.config')

local function load()
  log.debug('start to load task config:')
  local global_conf = {}
  local local_conf = {}
  if vim.fn.filereadable(vim.fn.expand(config.global_tasks)) == 1 then
    global_conf = toml.parse_file(vim.fn.expand(config.global_tasks))
    for _, v in pairs(global_conf) do
      v.isGlobal = true
    end
    log.debug('found global conf:\n' .. vim.inspect(global_conf))
  end
  if vim.fn.filereadable(vim.fn.expand(config.local_tasks)) == 1 then
    local_conf = toml.parse_file(vim.fn.expand(config.local_tasks))
    log.debug('found local conf:\n' .. vim.inspect(local_conf))
  end
  task_config = vim.tbl_extend('force', global_conf, local_conf)
end

local function init_variables()
  local ok = pcall(function()
    variables.workspaceFolder = util.unify_path(require('rooter').current_root())
  end)
  if not ok then
    variables.workspaceFolder = vim.fn.getcwd()
  end
  variables.workspaceFolderBasename = vim.fn.fnamemodify(variables.workspaceFolder, ':t')
  variables.file = util.unify_path(vim.fn.expand('%:p'))
  variables.relativeFile = util.unify_path(vim.fn.expand('%'), ':.')
  variables.relativeFileDirname = util.unify_path(vim.fn.expand('%'), ':h')
  variables.fileBasename = vim.fn.expand('%:t')
  variables.fileBasenameNoExtension = vim.fn.expand('%:t:r')
  variables.fileDirname = util.unify_path(vim.fn.expand('%:p:h'))
  variables.fileExtname = vim.fn.expand('%:e')
  variables.lineNumber = vim.fn.line('.')
  variables.selectedText = ''
  variables.execPath = ''
end

local function select_task(taskName)
  selected_task = task_config[taskName]
end

local function pick()
  selected_task = {}
  local ques = {}
  for key, _ in pairs(task_config) do
    local task_name
    if task_config[key].isGlobal then
      task_name = key .. '(global)'
    elseif task_config[key].isDetected then
      task_name = task_config[key].detectedName .. key .. '(detected)'
    else
      task_name = key
    end
    table.insert(ques, { task_name, select_task, { key } })
  end

  util.menu(ques)
  return selected_task
end

local function replace_variables(str)
  for key, value in pairs(variables) do
    str = vim.fn.substitute(str, '${' .. key .. '}', value, 'g')
  end
  return str
end

local function map(t, f)
  local rst = {}
  for _, v in ipairs(t) do
    table.insert(rst, f(v))
  end
  return rst
end

local function expand_task(task)
  if task.windows and util.isWindows then
    task = task.windows
  elseif task.osx and util.isOSX then
    task = task.osx
  elseif task.linux and util.isLinux then
    task = task.linux
  end
  if task.command and type(task.command) == 'string' then
    task.command = replace_variables(task.command)
  end
  if task.args and type(task.args) == 'table' then
    task.args = map(task.args, replace_variables)
  end
  if task.options and type(task.options) == 'table' then
    if task.options.cwd and type(task.options.cwd) == 'string' then
      task.options.cwd = replace_variables(task.options.cwd)
    end
  end
  return task
end

function M.edit(global)
  if global then
    vim.cmd.edit(config.global_tasks)
  else
    vim.cmd.edit(config.local_tasks)
  end
end

function M.get()
  load()
  for _, provider in ipairs(providers) do
    task_config = vim.tbl_deep_extend('force', task_config, provider())
  end
  init_variables()
  local task = expand_task(pick())
  return task
end

function M.expand_task(t)
  init_variables()
  return expand_task(t)
end

local function open_task()
  local line = vim.fn.getline('.')
  local task
  if string.find(line, '^%[.*%]') then
    task = string.sub(vim.fn.matchstr(line, '^\\[.*\\]'), 2, -2)
    vim.cmd('close')
    require('spacevim.plugin.runner').run_task(expand_task(task_config[task]))
  end
end

local function open_tasks_list_win()
  if task_viewer_bufnr ~= 0 and vim.api.nvim_buf_is_valid(task_viewer_bufnr) then
    vim.cmd('bd ' .. task_viewer_bufnr)
  end
  vim.cmd('botright split __tasks_info__')
  local lines = vim.o.lines * 30 / 100
  vim.cmd('resize ' .. lines)
  vim.cmd([[
  setlocal buftype=nofile bufhidden=wipe nobuflisted nolist nomodifiable
        \ noswapfile
        \ nowrap
        \ cursorline
        \ nospell
        \ nonu
        \ norelativenumber
        \ winfixheight
        \ nomodifiable
  set filetype=tasks-nvim-info
  ]])
  task_viewer_bufnr = vim.fn.bufnr('%')
  vim.api.nvim_buf_set_keymap(task_viewer_bufnr, 'n', '<Enter>', '', {
    callback = open_task,
  })
end

local function update_tasks_win_context()
  local lines = { 'Task                    Type          Description' }
  for task, _ in pairs(task_config) do
    local line
    if task_config[task].isGlobal then
      line = '[' .. task .. ']' .. string.rep(' ', 22 - #task, '') .. 'global        '
    elseif task_config[task].isDetected then
      line = '['
        .. task_config[task].detectedName
        .. task
        .. ']'
        .. string.rep(' ', 22 - vim.fn.strlen(task .. task_config[task].detectedName), '')
        .. 'detected      '
    else
      line = '[' .. task .. ']' .. string.rep(' ', 22 - #task, '') .. 'local         '
    end
    if task_config[task].description then
      line = line .. task_config[task].description
    else
      local argv = task_config[task].args or {}

      line = line .. task_config[task].command .. ' ' .. table.concat(argv, ' ')
    end
    table.insert(lines, line)
  end
  vim.api.nvim_buf_set_option(task_viewer_bufnr, 'modifiable', true)
  vim.api.nvim_buf_set_lines(task_viewer_bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(task_viewer_bufnr, 'modifiable', false)
end

function M.list()
  load()
  for _, provider in ipairs(providers) do
    task_config = vim.tbl_deep_extend('force', task_config, provider())
  end
  init_variables()
  open_tasks_list_win()
  update_tasks_win_context()
end

function M.reg_provider(provider)
  table.insert(providers, provider)
end

function M.get_tasks()
  load()
  for _, provider in ipairs(providers) do
    task_config = vim.tbl_deep_extend('force', task_config, provider())
  end
  init_variables()
  return task_config
end

function M.setup(opt)
  config.setup(opt or {})
end

return M
