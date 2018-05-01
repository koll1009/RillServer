local skynet = require "skynet"

local runconf = require(skynet.getenv("runconfig"))
local servconf = runconf.service
local MAX_CENTER_COUNT = #servconf.center


local M = {}
local centers = {}

local function init()
    for i = 1, MAX_CENTER_COUNT do
        centers[i] = string.format("center%d", i)
    end
end

function M.fetch_centerd(uid)
    local id = uid % MAX_CENTER_COUNT + 1
    assert(centers[id])
    return centers[id]
end

function M.login(uid, data)
    local center = M.fetch_centerd(uid)
    return skynet.call(center, "lua", "login.login", uid, data)
end

function M.register(uid, data)
    local center = M.fetch_centerd(uid)
    return skynet.call(center, "lua", "login.register", uid, data)
end

function M.logout(uid, key)
    local center = M.fetch_centerd(uid)
    return skynet.call(center, "lua", "login.logout", uid, key)
end

function M.broadcast(cmd, ...)
    for i = 1, MAX_CENTER_COUNT do
        skynet.send(centers[i], "lua", cmd, ...)
    end
end

function M.send2client(uid, msg)
    local center = M.fetch_centerd(uid)
	skynet.call(center, "lua", "broadcast.send2client", uid, msg)
end

function M.broadcast2client(msg)
	M.broadcast("broadcast.broadcast2client", msg)
end

skynet.init(init)



return M


