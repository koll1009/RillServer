local skynet = require "skynet"
require "skynet.manager"

local cluster = require "skynet.cluster"
local runconf = require(skynet.getenv("runconfig"))
local servconf = runconf.service
local nodename = skynet.getenv("nodename")


local function start_console()
	for i,v in pairs(servconf.debug_console) do
		if nodename == v.node then
			skynet.uniqueservice("debug_console", v.port)
			DEBUG("start debug_console in port: " .. v.port.."...")
		end
	end
end

skynet.start(function()
	INFO("Server start version: " .. runconf.version)
	--集群信息
	cluster.reload(runconf.cluster)
	cluster.open(nodename)
	--开启各个服务
	start_console()
	--exit
    skynet.exit()
end)


