local skynet = require "skynet"
local lfstool = require "lfstool"
local env = require "faci.env"
local event = require "faci.event"
local reload = require "reload"

local M = {}

function M.get_env(file)
	ok, result = reload.reload(file)
	return ok, result
end

function M.reload_module(file)
	ok, result = reload.reload(file)
	return ok, result
end

function M.reload_modules()
	local path = skynet.getenv("app_root").."mod/"..env.name
	lfstool.attrdir(path, function(file)
	local file = string.match(file, ".*mod/(.*)%.lua")
		if file then
			INFO(string.format("%s%d reload file:%s", env.name, env.id, file))
			ok, result = reload.reload(file)
		end
	end)
	return ok, result
end

--通过 env的 mod 名 require 文件
local function require_modules()
	local path = skynet.getenv("app_root").."mod/"..env.name
	lfstool.attrdir(path, function(file)
	local file = string.match(file, ".*mod/(.*)%.lua")
		if file then
			INFO(string.format("%s%d require file:%s", env.name, env.id, file))
			require(file)
		end
	end)
end

local module = {}
function M.get_module(name)
	--模块处理函数
	env.module[name] = env.module[name] or {
		dispatch = {},
		forward = {},
		event = {},
		watch = nil,
	}
	--模块全局变量
	env.static[name] = env.static[name] or {
	}
	return env.module[name], env.static[name]
end


local event_cache = {}
function M.fire_event(name, ...)
	DEBUG("fire event->", name, inspect(table.pack(...)) )

	if not event.can_fire(name) then
		ERROR("-----fire event fail, event->", name, " is not define------")
		return
	end
	--获取列表
	local cache = event_cache[name]
	if not cache then
		event_cache[name] = {}
		for i, v in pairs(env.module) do
			if type(v.event[name]) == "function" then
				table.insert(event_cache[name], v.event[name])
			end
		end
	end
	cache = event_cache[name]
	--执行注册时间 function
	for _, fun in ipairs(cache) do
		xpcall(fun, function(err) 
			ERROR("error msg", inspect(err))
			ERROR(debug.traceback())
		end, ...)
	end
end

function M.init_modules()
	require_modules()
end


return M