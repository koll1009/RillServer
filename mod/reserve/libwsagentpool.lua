local skynet = require "skynet"


local runconf = require(skynet.getenv("runconfig"))
local servconf = runconf.service

local M = {}

local agentpool = {}
local agentpool_num = 0

local function init()
	local node = skynet.getenv("nodename")
	for i,v in pairs(servconf.agentpool) do
		if node == v.node then
			table.insert(agentpool, string.format("agentpool%d", i))
			agentpool_num = agentpool_num + 1
		end
	end
end


function M.get()
    local pool = agentpool[math.random(1, agentpool_num)]
    return skynet.call(pool, "lua", "get")
end

function M.recycle(agent)
    local pool = agentpool[math.random(1, agentpool_num)]
    return skynet.call(pool, "lua", "recycle", agent)
end

function M.login(data)
    local agent = M.get()
    local isok = skynet.call(agent, "lua", "start", data)
    return isok, agent
end 


skynet.init(init)

return M


