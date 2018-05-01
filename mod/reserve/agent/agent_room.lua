local skynet = require "skynet"
local log = require "log"
local env = require "faci.env"

local libcenter = require "libcenter"
local libdbproxy = require "libdbproxy"

local runconf = require(skynet.getenv("runconfig"))
local games_common = runconf.games_common

local libmodules = {}

local function init_modules()
	setmetatable(libmodules, {
		__index = function(t, k)
			local mod = games_common[k]
			if not mod then
				return nil
			end
			local v = require(mod)
			t[k] = v
			return v
		end
	})
end
init_modules() -- local libmove = require "libmove"



local M = env.dispatch
local room_id = nil --房间id
local create_id = nil 
local lib = nil

local function cal_lib(game)
	return assert(libmodules[game])
end

function M.create_room(msg) 
	lib = cal_lib(msg.game)
	if not lib then
		ERROR("game not found: ", msg.game)
		msg.error = "game not found"
		return 
	end 

	create_id = libdbproxy.inc_room()  
	lib.create(create_id)
end 

function M.enter_room(msg)
	if room_id then
		INFO("enter room fail, already in room")
		return msg
	end
	--暂时 这样处理
	if not msg.id and create_id then
		msg.id = create_id
	end 
	
	local data = {
		uid = env.get_player().uid,
		agent = skynet.self(),
		node = node,
	}

	local isok, forward, data = lib.enter(msg.id, data)
	if isok  then
		msg.result = 0
		room_id = msg.id
	else
		msg.result = 1
	end
	return msg
end

function M.leave_room(msg)
	if not room_id then
		return
	end
	-- env.service["movegame"] = nil
	local uid = env.get_player().uid
    if lib.leave(room_id, uid) then
		room_id = nil
	end
	return msg
end


-- --示例1 echo
-- function M.echo(msg)
--     local cmd = msg.cmd
-- 	local str = msg.str
-- 	skynet.error("agent echo ! "..cmd.." "..str)
-- 	return msg
-- end

-- --示例2 name
-- function M.set_name(msg)
--     local cmd = msg.cmd
-- 	local str = msg.str
-- 	local playerdata = env.get_playerdata()
	
-- 	skynet.error("name "..cmd.." "..(playerdata.player.name or "none"))
-- 	skynet.error("set_name "..cmd.." "..str)
-- 	skynet.error("login_time "..cmd.." "..playerdata.player.login_time)
	
-- 	playerdata.player.name = str
	
-- 	--msg.str="succ"
-- 	return msg
-- end

-- --示例3 chat
-- function M.chat(msg)
--     local cmd = msg.cmd
-- 	local str = msg.str
-- 	libcenter.broadcast(env.get_player().uid, "broadcast_msg", msg)
-- 	skynet.error("agent chat 999! "..cmd.." "..str)
-- 	return nil
-- end

-- --示例4 测试热更
-- local reload = require "reload"

-- function M.chatreload(msg)
--     local cmd = msg.cmd
-- 	local str = msg.str
-- 	--注意agent_init中require的形式
-- 	--这种热更只能更新本服
-- 	reload.loadmod("agent.agent_room")
-- 	return nil
-- end
