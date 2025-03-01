local config = {}

config.global_tasks = '~/.tasks.toml'
config.local_tasks = '.tasks.toml'
config.provider = {'npm'}

function config.setup(opt)
  config.global_tasks = opt.global_tasks or config.global_tasks
  config.local_tasks = opt.local_tasks or config.local_tasks
  for _, p in ipairs(config.provider) do
     local ok, pf = pcall(require, 'tasks.provider.' .. p)
     if ok then
        require('tasks').reg_provider(pf)
     end
  end
end

return config
