local skynet = require "skynet"
local cluster = require "skynet.cluster"
local runconf = require(skynet.getenv("runconfig"))
local tool = require "tool"

local faci = require "faci.module"
local module = faci.get_module("reload")
local dispatch = module.dispatch
local forward = module.forward
local event = module.event

local function call_clusters(ignore, ...) --ignore -> ignore self
	for node, _ in pairs(runconf.cluster) do
		if not ignore or node ~= skynet.getenv("nodename") then
			pcall(cluster.call, node, "host", ...)
		end
	end
end



function dispatch.host_mod(addr, fd ,q)
	local service_name = q.name
	local mod = q.mod or "ALL"
	log.debug("start reload %s ...", mod)
	
	local list = {}
	local services = skynet.call(".launcher", "lua", "LIST")
    for k, v in pairs(services) do
        local cmd = string.match(v, "snlua (%w+) *.*")
        if cmd == service_name then
			log.debug("reload %s", cmd)
            local diff_time = skynet.call(k, "debug", "RELOAD", mod)
            list[skynet.address(k)] = string.format("%.2fs (%s)", diff_time, v)
        end
    end
	log.info("host_mod %s", tool.dump(list))
	return list
end


function dispatch.host_setup(addr, fd ,q)
	--全服
	if not q.mod then
		local ret = skynet.call("setup", "lua", "setup.update_all")
		return ret
	end
	--某个模块 eg:itemlist
	local ret = skynet.call("setup", "lua", "setup.update", q.mod)
end

function dispatch.setup(addr, fd ,q)
	call_clusters(false, "reload.host_setup", addr, fd ,q)
	return "update"
end

function dispatch.mod(addr, fd ,q)
	call_clusters(false, "reload.host_mod", addr, fd ,q)
	return "reload mod"
end



