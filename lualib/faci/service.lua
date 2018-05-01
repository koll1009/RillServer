--fici->facilitate 

local skynet = require "skynet"
local dispatch = require "faci.dispatch"
local module = require "faci.module"
local env = require "faci.env"
local log = require "log"

local faci_module = module.get_module("faci")
local faci_dispatch =  faci_module.dispatch

local service = {}

function service.init(name, id)
	env.name = name or "nameless server"
	env.id = tonumber(id) or 0
end

local function init()
	--名字和编号
	local name = env.name
	local id = env.id
	if not name then
		return
	end
	--命名
	local idstr = env.id > 0 and tostring(env.id) or ""
	local name = string.format("%s%s", name, idstr)
	skynet.name(name, skynet.self())
	--设置
	log.set_name(name)
	--全局变量
	_G["env"] = env
	_G["log"] = log
	--模块
	module.init_modules()
	module.fire_event("awake")
	module.fire_event("start")
	DEBUG("start ok "..name.."...")
end

function env.exit()
	module.fire_event("exit")
end

skynet.start(function()
	init()
    if env.init then
        env.init()
    end
end)


function faci_dispatch.stop()
	if type(env.exit) == "function" then
		xpcall(env.exit, function(err)
			log.error(tostring(err))
			log.error(debug.traceback()) 
		end)
	end
	skynet.exit()
end

return service



