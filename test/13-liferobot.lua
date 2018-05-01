local w = require "wsclient"
local uid
local STATUS = {idel=1, game=2}
local status = 0
seed = arg[1] or os.time()

--1-登陆 -> 请求进入房间
function login_Login(msg)
	print("onRecv.login_Login")
	status = STATUS.idel
	uid = msg.uid
	--w.send("life.enter_room", {})
	--w.send("example.echo", {str = "echo "..uid})
end

--2-进入房间
function life_enter_room(msg)
	status = STATUS.game
	w.send("life.update_map", {})
	w.send("life.list", {""})
	print("onRecv.life_enter_room")
end

--3-收到地图信息
function life_update_map(msg)
	print("onRecv.update_map")
end

--4-收到同步协议

function life_sync(msg)
	print("onRecv.life_list")
	--移动
	local rmsg = {}
	if math.random(1,100) < 5 then
		x = math.random(-1,1)
		rmsg.x = x
	end
	if math.random(1,100) < 5 then
		rmsg.action = 1
	end
	
	if rmsg.x or rmsg.action then
		w.send("life.input", rmsg)
	end

	--离开
	if math.random(1, 30*60) < 2 then
		w.send("life.leave", {})
		status = STATUS.idel
	end
	--意外退出
	if math.random(1, 30*60*20) < 2 then
		w.stop = true
	end
end

--2-进入房间
function example_echo(msg)
	w.send("example.echo", {str = "echo "..uid})
	print("onRecv.example_echo")
end


function onTimer()
	if status == STATUS.idel then
		if math.random(1, 10*300) < 2 then
			w.send("life.enter_room", {})
		end
	end
end

function onRecv(msg)
	funname = string.gsub(msg._cmd, "%.", "_");
	print(funname)
	if _G[funname] then
		_G[funname](msg)
	end
end

math.randomseed(seed)

w.sleep(math.random(10,20))
w.connect("127.0.0.1", 8799, onRecv, onTimer)
local account = "robot"..math.random(1,99999999)
w.login(account, "123456", OnLogin)
w.start(onRecv)

os.execute("sleep 1")