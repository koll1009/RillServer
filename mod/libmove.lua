local skynet = require "skynet"
local log = require "log"
local M = {}

local runconf = require(skynet.getenv("runconfig"))
local moveconf = runconf.movegame
local MAX_GLOBAL_COUNT = #moveconf.global


local function fetch_global(id)
    local index = id % MAX_GLOBAL_COUNT + 1
    return moveconf.global[index]
end

local function call(cmd, id, ...)
	local global = fetch_global(id)
	return skynet.call(global, "lua", cmd, id, ...)
end


function M.create(id)
	return call("movegame.create", id)
end

function M.enter(id, uid, data)
	return call("movegame.enter", id, uid, data)
end

function M.leave(id, uid)
	return call("movegame.leave", id, uid)
end

function M.get_forward(id)
	return fetch_global(id)
end


return M
