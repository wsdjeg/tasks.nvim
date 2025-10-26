local M = {}
local taskmanager = require('tasks')

local widths = {
  { width = 25 },
  { width = 10 },
  { width = 15 },
}

function M.get()
  local items = {}

  for k, v in pairs(taskmanager.get_tasks()) do
    local desc = v.description
    if desc == nil then
      desc = v.command
      if v.args ~= nil then
        desc = desc .. ' ' .. table.concat(v.args, ' ')
      end
    end
    local task_name = k
    local task_type = 'local'
    if v.isGlobal == 1 then
      task_type = 'global'
    elseif v.isDetected == 1 then
      task_type = 'detected'
      task_name = (v.detectedName or '') .. task_name
    end
    local background = 'no-background'
    if v.isBackground then
      background = 'background'
    end
    local str = string.format(
      '[%s] %s [%s] %s [%s] %s %s',
      task_name,
      string.rep(' ', widths[1].width - #task_name - 3),
      task_type,
      string.rep(' ', widths[2].width - #task_type - 3),
      background,
      task_type,
      string.rep(' ', widths[3].width - #background - 3),
      desc
    )
    table.insert(items, {
      value = v,
      str = str,
      highlight = {
        { 0, widths[1].width, 'String' },
        { widths[1].width, widths[1].width + widths[2].width, 'Tag' },
        {
          widths[1].width + widths[2].width,
          widths[1].width + widths[2].width + widths[3].width + 2,
          'Number',
        },
        {
          widths[1].width + widths[2].width + widths[3].width + 2,
          #str,
          'Comment',
        },
      },
    })
  end
  return items
end

function M.default_action(entry)
  local ok, runner = pcall(require, 'code-runner')
  if ok then
    runner.run_task(taskmanager.expand_task(entry.value))
  end
end

return M
