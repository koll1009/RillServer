local skynet = require "skynet"
local log = require "log"
local M = {}

local runconf = require(skynet.getenv("runconfig"))
local servconf = runconf.service
local lifeconf = runconf.lifegame
local MAX_GLOBAL_COUNT = #lifeconf.global
local node = skynet.getenv("nodename")

local function fetch_global(id)
    local index = id % MAX_GLOBAL_COUNT + 1
    return lifeconf.global[index]
end

local function call(cmd, id, ...)
	local global = fetch_global(id)
	assert(global)
	return skynet.call(global, "lua", cmd, id, ...)
end

local function callmgr(cmd, ...)
	local global = lifeconf.mgr
	assert(global)
	return skynet.call(global, "lua", cmd, ...)
end

local function sendmgr(cmd, ...)
	local global = lifeconf.mgr
	assert(global)
	return skynet.send(global, "lua", cmd, ...)
end

function M.create()
	local id = callmgr("lifemgr.create")
	call("life.create", id)
	return id
end

function M.enter(uid, data)
	local id = callmgr("lifemgr.recommend")
	--如果需要创建房间
	if id == 0 then
		id = M.create()
	end
	--进入
	if call("life.enter", id, uid, data) then
		callmgr("lifemgr.addplayer", id)
		return true, id
	else
		return false
	end
end

function M.leave(id, uid)
	if call("life.leave", id, uid) then
		callmgr("lifemgr.leave", id)
		return true
	else
		return false
	end
end

function M.delete(id)
	sendmgr("lifemgr.delete", id)
end

function M.get_forward(id)
	return fetch_global(id)
end

return M
