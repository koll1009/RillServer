local skynet = require "skynet"
local cluster = require "skynet.cluster"

local faci = require "faci.module"
local module = faci.get_module("broadcast")
local dispatch = module.dispatch
local forward = module.forward
local event = module.event

function dispatch.broadcast2client(msg)
	for uid, uid_data in pairs(env.users) do
		log.debug("center broadcast_msg send to: " .. uid)
		dispatch.send2client(uid, msg)
	end
end

--发送
local function send(node, adress, cmd, ...)
	if node == skynet.getenv("nodename") then
		skynet.send(adress, "lua", cmd, ...)
	else 
		cluster.send(node, adress, cmd, ...)
	end
end

--发送给某个client
function dispatch.send2client(uid, msg)
	local user = env.users[uid]
	--未登陆
	if not user then
		log.debug("center send_agent not user " .. uid)
		return
	end
	--未绑定agent
	if not user.agent then
		log.debug("center send_agent not user.game " .. uid)
		return
	end
	
	send(user.node, user.agent, "send2client", msg)
end
