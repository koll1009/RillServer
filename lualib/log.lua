local skynet = require "skynet"
local logger = {}

local loglevel = {
    debug = 1,
    info = 2,
    warn = 3,
    err = 4,
}

local function init_log_level()
    if not logger._level then
        local level = skynet.getenv("log_level")
        local default_level = loglevel.debug
        local val

        if not level or not loglevel[level] then
            val = default_level
        else
            val = loglevel[level]
        end

        logger._level = val
    end
end

local function logmsg(loglevel, format, ...)
	local n = logger._name and string.format("[%s:] ", logger._name) or ""
    skynet.error(n..string.format(format, ...))
end

function logger.set_log_level(level)
    local val = loglevel.debug

    if level and loglevel[level] then
        val = loglevel[level]
    end

    logger._level = val
end

function logger.debug(format, ...)
    if logger._level <= loglevel.debug then
        logmsg(loglevel.debug, format, ...)
    end
end

function logger.info(format, ...)
    if logger._level <= loglevel.info then
        logmsg(loglevel.info, format, ...)
    end
end

function logger.warn(format, ...)
    if logger._level <= loglevel.warn then
        logmsg(loglevel.warn, format, ...)
    end
end

function logger.error(format, ...)
    if logger._level <= loglevel.err then
        logmsg(loglevel.error, format, ...)
    end
end

init_log_level()

function logger.set_name(name)
    logger._name = name
end

return logger

