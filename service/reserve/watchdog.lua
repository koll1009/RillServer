local skynet = require "skynet"
local log = require "log"
local protopack = require "protopack"
local socket = require "socket"

local gate
local SOCKET = {}
local agents = {}

-- agent 池的名字
local agentpool = ...

---------------------------socket数据处理----------------------------
local sock_handler = {}
sock_handler.login = function (fd, msg)
	
    msg.fd = fd
    msg.watchdog = skynet.self()

    local ret = skynet.call(".login", "lua", "login", msg)
    if ret then
        agents[fd] = skynet.call(agentpool, "lua", "get")
        skynet.call(agents[fd], "lua", "start", 
                    {
                        gate = gate, 
                        fd = fd, 
                        watchdog = skynet.self(), 
                        account = ret,
                    })
        
        log.log("verify account %s success!", msg.account)
	else
		SOCKET.send(fd, "login", {ret=ret})
		skynet.call(gate,"lua","kick",fd)
		log.log("verify account %s fail!")
    end
end

sock_handler.register = function (fd, msg)
    local ret = skynet.call(".login", "lua", "register", msg)
	SOCKET.send(fd, "register", {ret = ret})
end


------------------------ socket消息开始 -----------------------------
function SOCKET.open(fd, addr)
	log.log("New client from : %s", addr)
	skynet.call(gate, "lua", "accept", fd)
end

local function close_agent(fd)
	local a = agents[fd]
	agents[fd] = nil
	if a then
		skynet.call(gate, "lua", "kick", fd)

        -- recycle agent
		skynet.call(agentpool, "lua", "recycle", a)
	end
end

function SOCKET.close(fd)
	log.log("socket close fd=%d", fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
	log.log("socket error fd = %d msg=%s", fd, msg)
	close_agent(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	log.log("socket warning fd=%d size=%d", fd, size)
end

function SOCKET.data(fd, data)
	local name, msg = protopack.unpack(data)
	print(name)
	sock_handler[name](fd, msg)
end

function SOCKET.send(fd, name, msg)
	local data = protopack.pack(name, msg)
	socket.write(fd, data)
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
	skynet.dispatch("lua", function(_, _, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)

	gate = skynet.newservice("gate")
end)

