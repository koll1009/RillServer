--lua 13-lifemgr.lua arg1 arg2
--参数1  分多少批
--参数2  每批多少个客户端

package.cpath = "../luaclib/?.so"
package.path = "../skynet/lualib/?.lua;../lualib/?.lua;../examples/?.lua"
local socket = require "clientwebsocket"
math.randomseed(os.time())
local count = 0
t1 = arg[1] or 100
t2 = arg[2] or 30
for i = 1, t1 do
	for j = 1, t2 do
		count = count + 1
		print("start robot bunch:"..i.." num:"..j.." count:"..count)
		local seed = math.random(1,999999)
		os.execute("nohup lua 13-liferobot.lua "..seed.." < /dev/null >/dev/null 2>&1 &")
		socket.usleep(math.random(30, 500))
	end
	socket.usleep(math.random(10*1000, 20*1000))
end