local skynet = require "skynet"
local log = require "log"

local runconf = require(skynet.getenv("runconfig"))
local servconf = runconf.service

local M = {}

local login = {}
local login_num = 0

local function init()
	local node = skynet.getenv("nodename")
	for i,v in pairs(servconf.login) do
		if node == v.node then
			table.insert(login, string.format("login%d", i))
			login_num = login_num + 1
		end
	end
end

local next_id = 1
function M.fetch_login()
    next_id = next_id % login_num + 1
    return login[next_id]
end




skynet.init(init)

return M


