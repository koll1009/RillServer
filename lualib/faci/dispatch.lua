local skynet = require "skynet"
require "skynet.manager"

local log = require "log"
local env = require "faci.env"
local protopack = require "protopack"
require "libstring"
local libsocket = require "libsocket"
local tool = require "tool"


local function traceback(err)
	ERROR(inspect(err))
	ERROR(debug.traceback())
end

local function watch(mod, acm)
	local m = env.module[mod]
	if not m then
		return true, nil
	end
	
	if type(m.watch) == "function" then
		return true, m.watch(acm)
	end
	return true, nil
end

local function lua_dispatch(session, addr, cmd, ...)
	local cmdlist = string.split(cmd, ".")
	local cmd1 = cmdlist[1]
	local cmd2 = cmdlist[2]
	--forward分发
	if cmd1 == "client_forward" and not cmd2 then
		local isok, msg = local_dispatch(...)
		skynet.retpack(isok, msg)
		return true
	elseif cmd1 == "watch" and not cmd2 then
		local isok, msg, acm = watch(...)
		skynet.retpack(isok, msg, acm)
		return true
	end
	--模块
	local module = env.module[cmd1]
	if type(module) ~= "table" then
		log.info("lua_dispatch module is not table, cmd = %s.%s", cmd1, cmd2)
		skynet.ret()
		return false
	end
	
	local dispatch = module.dispatch
	if type(dispatch) ~= "table" then
		log.info("lua_dispatch dispatch is not table, cmd = %s.%s", cmd1, cmd2)
		skynet.ret()
		return false
	end
	
	local cb = dispatch[cmd2]
	if type(cb) ~= "function" then
		log.info("lua_dispatch cb is not function, cmd = %s.%s", cmd1, cmd2)
		skynet.ret()
		return false
	end
	
	--分发
	local function skyret(ok, ...)
		if not ok then
			skynet.ret()
		else
			skynet.retpack(...)
		end
	end
	local ret = {xpcall(cb, traceback, ...)}
	local isok = ret[1]
	if not isok then
		INFO("lua_dispatch cb call fail===> cmd: ", cmd1 .. "." .. cmd2, " ret:",inspect(ret) )
		skynet.ret()
		return false
	end
	
	skyret(table.unpack(ret))
end


--获取fd或者player实体
local function get_v(fd)
	local uid = env.fds[fd]
	if uid then
		return  env.players[uid]
	else
		return  fd
	end
end

--远程分发
function romote_dispatch(cmd1, cmd2, fd, msg, source)
	local uid = env.fds[fd]
	local player = env.players[uid] 
	if not player then
        log.error("romote_dispatch player(fd:%s) is not exist, cmd = %s.%s", fd, cmd1, cmd2)
        return false
    end
    local adress = player.romote[cmd1] --eg:global1
    if not adress then
        log.error("romote_dispatch adress(%s) is not exist, cmd = %s", cmd1, cmd2)
        return false
    end
	
	local uid = get_v(fd).uid
	log.info("client_forward %s.%s", cmd1, cmd2)
    local isok, ret = skynet.call(adress, "lua", "client_forward", cmd1, cmd2, uid, msg, source)
	return isok, ret 
end

--本地分发
function local_dispatch(cmd1, cmd2, fd, msg, source)
	local module = env.module[cmd1]
	if type(module) ~= "table" then
		log.info("local_dispatch module is not table, cmd = %s.%s, msg = %s", cmd1, cmd2, tool.dump(msg))
		return false
	end

	local forward = module.forward
	if type(forward) ~= "table" then
		log.info("local_dispatch forward is not table, cmd = %s.%s, msg = %s", cmd1, cmd2, tool.dump(msg))
		return false
	end
	
	local cb = forward[cmd2]
	if type(cb) ~= "function" then
		log.info("local_dispatch cb is not function, cmd = %s.%s, str = %s", cmd1, cmd2, tool.dump(msg))
		return false
	end
	--开始分发
    local isok, ret = xpcall(cb, traceback, get_v(fd), msg, source)
    if not isok then
        log.error("local_dispatch handle msg error, cmd = %s, msg = %s, err=%s", cmd1, tool.dump(msg), ret)
		return true --报错的情况也表示分发到位
    end
	
    return true, ret 
end

function client_dispatch(session, source, str)
	--特殊用法，将session用作fd，减少再次转发给gate
	local fd = session
	local cmd, check, msg = protopack.unpack(str)
	if not cmd then
		skynet.send(source, "lua", "kick", fd)
		return
	end
	msg._cmd = cmd
	msg._check = check
	--TODO check校验
	local cmdlist = string.split(cmd, ".")
	local isok, ret
	--派发到本服
	isok, ret = local_dispatch(cmdlist[1], cmdlist[2], fd, msg, source)
	--派发到远端
	if not isok then
		isok, ret = romote_dispatch(cmdlist[1], cmdlist[2], fd, msg, source)
	end
	
	if ret then
		local rcmd, rcheck = ret._cmd, ret._check
		ret._cmd = nil
		ret._check = nil
		local data = protopack.pack(rcmd, rcheck, ret)
		libsocket.send(fd, data)
	end
end


skynet.dispatch("lua", lua_dispatch)

skynet.register_protocol{
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = skynet.tostring,
	dispatch = client_dispatch, 
}
