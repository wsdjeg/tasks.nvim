local M = {}
local log
function M.info(msg)
    if not log then
        local ok, l = pcall(require, 'logger')
        if ok then
            log = l.derive('tasks')
            log.info(msg)
        end
    else
        log.info(msg)
    end
end
function M.debug(msg)
    if not log then
        local ok, l = pcall(require, 'logger')
        if ok then
            log = l.derive('tasks')
            log.debug(msg)
        end
    else
        log.debug(msg)
    end
end
function M.warn(msg)
    if not log then
        local ok, l = pcall(require, 'logger')
        if ok then
            log = l.derive('tasks')
            log.warn(msg)
        end
    else
        log.warn(msg)
    end
end
function M.error(msg)
    if not log then
        local ok, l = pcall(require, 'logger')
        if ok then
            log = l.derive('tasks')
            log.error(msg)
        end
    else
        log.error(msg)
    end
end

return M
