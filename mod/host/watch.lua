local skynet = require "skynet"
local cluster = require "skynet.cluster"
local runconf = require(skynet.getenv("runconfig"))
local tool = require "tool"

local faci = require "faci.module"
local module = faci.get_module("watch")
local dispatch = module.dispatch

--http://123.207.111.118:8111/?cmd=watch.watch&name=center&mod=login
--http://123.207.111.118:8111/?cmd=watch.watch&name=global&mod=life
--http://123.207.111.118:8111/?cmd=watch.watch&name=global&mod=lifemgr
--http://123.207.111.118:8111/?cmd=watch.watch&name=game&mod=login
function dispatch.host_watch(addr, fd ,q, acm)
	local service_name = q.name or "center"
	local mod = q.mod or "login"
	local t = {}
	local services = skynet.call(".launcher", "lua", "LIST")
    for k, v in pairs(services) do
		local cmd, name, id = string.match(v, "snlua (%w+) (%w+) (%w+)")
        if cmd == service_name then
			log.debug("watch %s %s %s", cmd, name, id)
            isok, ret, acm = skynet.call(k, "lua", "watch", mod, acm)
			t[name..id] = ret
		end
	end
	return t, acm
end


function dispatch.watch(addr, fd ,q)
	log.info("dispatch.watch")
	local t = {}
	local acm = {}  --accumulate 累积
	for node, _ in pairs(runconf.cluster) do
		log.info("call node %s", node)
		local isok, ret, acmret = pcall(cluster.call, node, "host", "watch.host_watch", addr, fd , q, acm)
		if isok then
			log.info("node return succ %s ret:%s acm:%s", node, tool.dump(ret), tool.dump(acm))
			t[node] = ret
			acm = acmret
		else
			log.info("node return fail %s", node)
			t[node] = "call node fail"
		end
	end
	t.accumulate = acm
	log.info("all node returnd %s", tool.dump(t))
	return tool.dump(t)
end