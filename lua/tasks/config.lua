local config = {}

config.global_tasks = '~/.tasks.toml'
config.local_tasks = 'tasks.toml'

function config.setup(opt)
  config.global_tasks = opt.global_tasks or config.global_tasks
  config.local_tasks = opt.local_tasks or config.local_tasks
end

return config
