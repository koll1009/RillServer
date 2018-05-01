local skynet = require "skynet"
local log = require "log"
local protopack = require "protopack"
local websocket = require"websocket"

local liblogin = require "liblogin"
local libagentpool = require "libwsagentpool"
local libcenter = require "libcenter"
local tool = require "tool"


local gate
local SOCKET = {}
local agents = {}
local uids = {}

---------------------------socket数据处理----------------------------
local sock_handler = {}
sock_handler.login = function (fd, msg)

    msg.watchdog = skynet.self()
    msg.fd = fd

    local isok, account = liblogin.login(msg)

    local resp = {}
    if not isok then
        resp.error = "login fail"
        return resp
    end

    uids[fd] = account.uid

    agents[fd] = libagentpool.get()
    skynet.call(agents[fd], "lua", "start", 
                {
                    gate = gate, 
                    fd = fd, 
                    watchdog = skynet.self(), 
                    account = account,
                })
    
    log.info("verify account %s success!", msg.account)

    resp.error = "login success"
    return resp
end

sock_handler.register = function (fd, msg)
    local ret = liblogin.register(msg)

    local resp = {}
    if ret then
    end
    return resp
end

------------------------ socket消息开始 -----------------------------
function SOCKET.open(fd, addr)
	log.info("New client from : %s", addr)
	skynet.call(gate,"lua","accept",fd)
end

local function close_agent(fd)
    local a = agents[fd]
	agents[fd] = nil
    log.info("=== close agent, fd: " .. fd)
	if a then
		skynet.call(gate, "lua", "kick", fd)
        
        local uid = uids[fd]
        libcenter.logout(uid)
        uids[fd] = nil

        log.info("=== close agent, uid: " .. uid)

        skynet.call(a, "lua", "disconnect")

        -- recycle agent
		libagentpool.recycle(a)
	end
end

function SOCKET.close(fd)
	log.info("socket close fd=%d", fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
	log.info("socket error fd = %d msg = %s",fd, msg)
	close_agent(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	log.info("socket warning fd=%d size=%d", fd, size)
end

function SOCKET.data(fd, data)
	local cmd, msg = protopack.unpack(data)
    if not cmd then
        log.error("sock data, cmd is nil")
        return
    end

    local f = sock_handler[cmd]
    if type(f) ~= "function" then
        log.error("sock data, fun is not exist, cmd: " .. cmd)
        return
    end

    local isok, ret = pcall(f, fd, msg)
    if not isok then
        log.error("sock data, call faile, cmd: " .. cmd .. " err: " .. ret)
        return
    end

    if ret then
        ret.seq = msg.seq

	    SOCKET.send(fd, cmd, ret)
    end
end

function SOCKET.send(fd, cmd, msg)
	local data = protopack.pack(cmd, msg)
	websocket:send_text(fd,data)
end

------------------------ socket消息结束-----------------------------

local CMD = {}
function CMD.start(conf)
	skynet.call(gate, "lua", "open" , conf)
end

function CMD.close(fd)
	close_agent(fd)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)
	gate = skynet.newservice("wsgate")
end)