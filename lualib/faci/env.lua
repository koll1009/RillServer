local M = {}
--服务器信息
M.name = "nameless server"
M.id = 0

--玩家列表和fd列表，只存在于game
--分发将会根据env.fds[fd]返回对应的player结构或直接传fd
M.players = {}
M.fds = {}

--模块
M.module = {
	--[[
	login = {
		--lua转发的消息
		dispatch = {},
		--转发的客户端消息
		forward = {},
		--事件
		event = {},
	}
	--]]
}

--全局变量
M.static = {
	--[[
		login = {}
	--]]
}

M.dispatch = {} --为了不报错，先调试模块相关的内容
M.forward = {}
return M

