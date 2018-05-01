local skynet = require "skynet"
local cluster = require "skynet.cluster"

local faci = require "faci.module"
local module = faci.get_module("stop")
local dispatch = module.dispatch
local forward = module.forward
local event = module.event

local runconf = require(skynet.getenv("runconfig"))

local stop_order = {"gataway","login","center","game","global","dbproxy"}
local stop_idx = 1

local function call_clusters(ignore, ...) --ignore -> ignore self
	for node, _ in pairs(runconf.cluster) do
		if not ignore or node ~= skynet.getenv("nodename") then
			pcall(cluster.call, node, "host", ...)
		end
	end
end

local function send_clusters(ignore_self, ...)
	for node, _ in pairs(runconf.cluster) do
		if not ignore or node ~= skynet.getenv("nodename") then
			pcall(cluster.send, node, "host", ...)
		end
	end
end


--由其他host调用
function dispatch.host_stop(name)
	local services = skynet.call(".launcher", "lua", "LIST")
	for k, v in pairs(services) do
		local n = string.match(v, "snlua (%w+) *.*")
		if n == name then
			skynet.send(k, "lua", "faci.stop")
		end
	end
end
		
function dispatch.host_abort()
	skynet.abort()
end

--查询某种服的数量
function dispatch.host_query(name)
	local count = 0
	local services = skynet.call(".launcher", "lua", "LIST")
	for k, v in pairs(services) do
		local n = string.match(v, "snlua (%w+) *.*")
		if n == name then
			count = count + 1
		end
	end
	return count
end

local function timer()
	local name = stop_order[stop_idx]
	--计算剩余数量
	local count = 0
	for node, _ in pairs(runconf.cluster) do
		local ret, num = pcall(cluster.call, node, "host", "stop.host_query")
		if ret then
			count = count + num
		end
	end
	--是否前进
	if count == 0 then
		stop_idx = stop_idx + 1
		--是否abort
		if stop_idx > #stop_order then
			call_clusters(true, "stop.host_abort")
			dispatch.host_abort()
		end 
		--前
		name = stop_order[stop_idx]
		log.info("stoping %s", name)
		send_clusters(false, "stop.host_stop", name)
	end
	skynet.timeout(10, timer)
end

function dispatch.stop()
	log.info("stoping %s", stop_order[1])
	stop_idx = 1
	send_clusters(false, "stop.host_stop", stop_order[1])
	
    skynet.timeout(10, timer)
end
