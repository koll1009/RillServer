local skynet = require "skynet"

local libdb = require "libdbproxy"
local libcenter = require "libcenter"
local libagentpool = require "libwsagentpool"

local faci = require "faci.module"

local key_seq = 1

local module = faci.get_module("login")
local dispatch = module.dispatch
local forward = module.forward
local event = module.event

local login_auth = require "login.login_auth"


function forward.login(fd, msg, source)
	local sdkid = msg.sdkid --ƽ̨ID
    local account = msg.account
	local password = msg.password
	--key
	key_seq = key_seq + 1
	local key = env.id*10000 + key_seq

	--login auth 
	local isok, uid = login_auth(sdkid, msg)
	if not isok then
		ERROR("+++++++++++ account: ",inspect(account), " login login_auth fail +++++++++")
		log.debug("%s login fail, wrong password ", account)
		msg.error = "login fail, wrong password"
		return msg
	end

	--center
	local data = {
		node = skynet.getenv("nodename"),
		fd = fd,
		gate = source,
		key = key,
	}
	if not libcenter.login(uid, data) then
		ERROR("+++++++++++", uid, " login fail, center login +++++++++")
		msg.error = "login fail, center login fail"
		return msg
	end
	--game
	data = {
		fd = fd,
		gate = source,
		account = {
			uid = uid,
			account = { 
				account = msg.account,
				password = msg.password,
			}
		}
	}
	local ret, agent = libagentpool.login(data)
	if not ret then
		libcenter.logout(uid, key)
		ERROR("++++++++++++", uid, " login fail, load data err +++++++++")
		msg.error = "login fail, load data err"
		return msg
	end
	--center
	local data = {
		agent = agent,
		key = key,
	}
	if not libcenter.register(uid, data) then
		libcenter.logout(uid, key)
		ERROR("++++++++++++", uid, " login fail, register center fail +++++++++")
		msg.error = "login fail, register center fail"
		return msg
	end
	--gate
	local data = {
		uid = uid,
		fd = fd,
		agent = agent,
		key = key
	}
	if not skynet.call(source, "lua", "register", data) then
		libcenter.logout(uid, key)
		ERROR("++++++++++++", uid, " login fail, register gate fail +++++++++")
		msg.error = "login fail, register gate fail"
		return msg
	end
	msg.uid = uid
	msg.error = "login success"
	
	INFO("++++++++++++++++login success uid:", uid, "++++++++++++++++++")
	return msg
end