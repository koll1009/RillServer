local skynet = require "skynet"
require "skynet.manager"

local loghandle = print

local MAX_LINE_COUNT = 100000

local filename 
local fd
local curlinecount = 0

local function fileloghandle(msg)
    if not fd then
        fd = io.open(filename, "a+")
        assert(fd ~= nil, "open file fail, filename: " .. filename)
    end
    fd:write(msg)
    fd:write('\n')
    fd:flush()

    curlinecount = curlinecount + 1 
    if curlinecount >= MAX_LINE_COUNT then
        io.close(fd)

        local date_str = os.date("%Y-%m-%d_%H:%M:%S")
        local rename = string.format("log/%s_%s", filename, date_str)
        local ret, err = os.rename(filename, rename)
        if not ret then
            skynet.error(string.format("rename %s fail, result: %s", rename, err))
        end 

        fd = io.open(filename, "a+")
        assert(fd ~= nil)
        curlinecount = 0
    end
end

local function init()
    filename = skynet.getenv("logfilename") 
    if filename then
        loghandle = fileloghandle
    end

    local linecount = skynet.getenv("logfilemaxline")
    if linecount then
        MAX_LINE_COUNT = tonumber(linecount)
    end
end

local function log(address, msg)
    local time, ms = string.match(skynet.time(), "(%d+)%.(%d+)")
    local date_str = os.date("%Y-%m-%d %H:%M:%S")
    loghandle(string.format(":%08x[%s.%02d]: %s", address, date_str, ms, msg))
end

skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	unpack = skynet.tostring,
	dispatch = function(_, address, msg)
        log(address, msg)
	end
}

skynet.register_protocol {
	name = "SYSTEM",
	id = skynet.PTYPE_SYSTEM,
	unpack = function(...) return ... end,
	dispatch = function()
		-- reopen signal
		print("SIGHUP")
	end
}

skynet.start(function()
    init()
	skynet.register ".logger"
end)


