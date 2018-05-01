local RoomMove = class('RoomMove')

local libcenter = require "libcenter"


function RoomMove:initialize()
    DEBUG("=============RoomMove Init=================")

    self._players = {}
end


function RoomMove:broadcast(msg, filter_uid)
    for k, v in pairs(self._players) do
        if filter_uid and filter_uid ~= k then
            libcenter.send2client(k, msg)
        end 
    end 
end 

	-- for i, v in pairs(room.players) do
	-- 	if i ~= uid then
	-- 		--优化方法，记录game和node，然后发送
	-- 		local msg = {cmd="movegame.add", uid=uid, x=x, y=y}
	-- 		libcenter.send2client(i, msg)
	-- 	end
    -- end
    


return RoomMove
