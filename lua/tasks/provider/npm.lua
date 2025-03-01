local function detect_npm_tasks()
  local detect_task = {}
  local conf = {}
  if vim.fn.filereadable('package.json') == 1 then
    conf = vim.json.decode(vim.fn.join(vim.fn.readfile('package.json', ''), ''))
  end
  if conf.scripts then
    for task_name, _ in pairs(conf.scripts) do
      detect_task[task_name] =
        { command = conf.scripts[task_name], isDetected = true, detectedName = 'npm:' }
    end
  end
  return detect_task
end

return detect_npm_tasks
