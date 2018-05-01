package.cpath = "../luaclib/?.so"
package.path = "../skynet/lualib/?.lua;../lualib/?.lua;../examples/?.lua"

if _VERSION ~= "Lua 5.3" then
	error "Use lua 5.3"
end


local socket = require "clientwebsocket"
local json = require "cjson"
local tool = require "tool"

local fd = assert(socket.connect("127.0.0.1", 8799))

local function request(name, args, session)
    local t = {
        _cmd = name,
        seq = session,
    }
    if type(args) == "table" then
        for k, v in pairs(args) do
            t[k] = v
        end
    end
    local str = json.encode(t)
    return str
end

local function send_package(fd, pack)
	socket.send(fd, pack)
end

local function recv_package()
	local r , istimeout= socket.recv(fd, 100)
	if not r then
		return nil
	end
	if r == ""  and istimeout == 0 then
		error "Server closed"
	end
	return r
end

local session = 0

local function send_request(name, args)
	session = session + 1
	local str = request(name, args, session)
	send_package(fd, str)
	
	print("Request:", str)
end


local function dispatch_package()
	while true do
		local v
		v = recv_package()
		if not v  or v == "" then
			break
		end
        
        print("recv: " .. tool.dump(v)) 
	end
end


print("your account: ")
send_request("login.Login", {account=4, password="11111"})

while true do
	dispatch_package()
	local msg = socket.readstdin()
	if msg then
		send_request("example.chat", { str = msg })
	else
		socket.usleep(2000)
	end
end

