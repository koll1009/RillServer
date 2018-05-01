local M = {}

M.events = {
	--服务器事件
	awake = 1,
	start = 1,
	exit = 1,		--程序退出时发生
	--玩家事件
	login = 1,
	logout = 1,
}

function M.can_fire(name)
	return M.events[name]
end



return M