--导入库文件
skynet_root = "../skynet/"
app_root = "../"
package.cpath = skynet_root.."luaclib/?.so;"..app_root.."luaclib/?.so"
package.path = "./?.lua;"..skynet_root.."lualib/?.lua;"..skynet_root.."lualib/compat10/?.lua;"..skynet_root.."lualib/?/init.lua;"..app_root.."etc/?.lua;"..app_root.."lualib/?.lua;"..app_root.."config/?.lua;"..app_root.."mod/?.lua;"
local protopack = require "protopackpb"
local json = require "cjson"
local tool = require "tool"
local socket = require "client.socket"


if _VERSION ~= "Lua 5.3" then
	error "Use lua 5.3"
end


--全局变量
local fd = 0
local check = 5

--一些方法

local function send(cmd, msg)
	local str = protopack.pack(cmd, check, msg)
	socket.send(fd, str)
	--print("Send:", tool.dump(msg))

	check = check + 1
end

local recvstr = ""
local function recv_package()
	local r , istimeout= socket.recv(fd, 10)
	if not r then
		return nil
	end
	if r == ""  and istimeout == 0 then
		error "Server closed"
	end
	
	--粘包分包
	recvstr = recvstr..r
	if string.len(recvstr) < 2 then
		return nil
	end

	local len = string.unpack("> i2", recvstr)
	while string.len(recvstr)-2 >= len do
		local f = string.format("> i2 c%d", len)
		local len, str = string.unpack(f, recvstr)
		
		local cmd, check, msg = protopack.unpack(str)
		--print(string.format("recv: %s -> %s",cmd, tool.dump(msg)))
		recvstr = string.sub(recvstr, len+1+2, string.len(recvstr))
	end
	
	return r
end

local function dispatch_package()
	while true do
		local v = recv_package()
		if not v  or v == "" then
			break
		end
	end
end

--连接
fd = assert(socket.connect("127.0.0.1", 8799))
--登录
send("login.Login", {account="2q", password="11111v"})
--执行
while true do
	dispatch_package()
	local msg = socket.readstdin()
	if msg then
		if msg == "exit" then 
			socket.close(1)
			os.exit()  
		end
		send("example.echo", { str = msg })
	else
		socket.usleep(2000)
	end
end
