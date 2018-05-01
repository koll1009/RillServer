local skynet = require "skynet"
local libcenter = require "libcenter"

local faci = require "faci.module"
local module = faci.get_module("movegame")
local dispatch = module.dispatch
local forward = module.forward
local event = module.event

--移动游戏
--[[
	room_id 
	addr 
]]
--room_id -->roominfo
local Room_Map = {
}

function dispatch.create(room_id)
	local addr = skynet.newservice("room_move", "room_move", room_id)
	skynet.call(addr, "lua", "room_api.start", "hello world")
	Room_Map[room_id] = {room_id = room_id, addr = addr,}
end

function dispatch.enter(room_id, data)
	local room = Room_Map[room_id]
	if not room then
		ERROR("movegame enter not room "..room_id)
		return false
	end

	local isok = skynet.call(room.addr, "lua", "room_api.enter", data)
	return isok, skynet.self(), room
end

function dispatch.leave(uid)
	local id = Player_Map[uid]
	
	local  room = Room_Map[id]
	if not room then
		skynet.error("movegame leave not room "..id)
		return false
	end

	return skynet.call(room.addr, "lua", "room_api.leave", uid)
end

-- --转发客户端发过来的消息
-- function forward.list(uid, msg)
-- 	local id = ids[uid]
-- 	local  room = rooms[id]
-- 	if not room then
-- 		skynet.error("movegame leave not room "..id)
-- 		return
-- 	end
	
-- 	msg={cmd="movegame.list",t=1}
-- 	msg.players = {}
-- 	for i,v in pairs(room.players) do
-- 		table.insert(msg.players,{x=v.x,y=v.y,uid=i})
-- 	end
-- 	return msg
-- end

-- --转发客户端发过来的消息
-- function forward.move(uid, data)
-- 	local id = ids[uid]
-- 	local  room = rooms[id]
-- 	if not room then
-- 		skynet.error("movegame move not room "..id)
-- 		return
-- 	end
-- 	local x = data.x
-- 	local y = data.y
-- 	skynet.error("movegame move "..uid.." "..x.." "..y)
-- 	local player = room.players[uid]
-- 	player.x = player.x + x
-- 	player.y = player.y + y
-- 	for i,v in pairs(room.players) do
-- 		libcenter.send2client(i, {cmd="movegame.move", uid=uid, x=player.x, y=player.y})
-- 	end
-- end