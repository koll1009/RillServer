local errors = {}

function errmsg(ec)
	if not ec then
		return "nil"
	end
	return errors[ec].desc
end

local function add(err)
	assert(errors[err.code] == nil, string.format("have the same error code[%x], msg[%s]", err.code, err.message))
	errors[err.code] = {desc = err.desc , type = err.type}
	return err.code
end

SYSTEM_ERROR = {
	success            = add{code = 0x0000, desc = "请求成功"},
}

AUTH_ERROR = {
	account_nil        = add{code = 0x0101, desc = "帐号为空"},
	password_nil       = add{code = 0x0102, desc = "密码为空"},
	telephone_nil      = add{code = 0x0103, desc = "电话号码为空"},
	account_exist      = add{code = 0x0104, desc = "帐号存在"},
	player_id_limit    = add{code = 0x0105, desc = "玩家id已达上限"},
	repeat_login       = add{code = 0x0106, desc = "重复登录"},
	account_not_exist  = add{code = 0x0107, desc = "不存在此帐号"},
	password_wrong     = add{code = 0x0108, desc = "密码错误"},
	player_not_exist   = add{code = 0x0109, desc = "对应的玩家不存在"},
	union_id_nil       = add{code = 0x010a, desc = "union_id为空"},
	head_url_nil       = add{code = 0x010b, desc = "头像地址为空"},
	nickname_nil       = add{code = 0x010c, desc = "昵称为空"},
	sex_nil            = add{code = 0x010d, desc = "性别为空"},
}

GAME_ERROR = {
	in_other_game = add{code = 0x0d01, desc = "在其它游戏中"},
	in_other_room = add{code = 0x0d02, desc = "在其它游戏房间中"},
	in_other_room_inst = add{code = 0x0d03, desc = "在其它的房间实例中游戏"},
	gold_not_enough = add{code = 0x0d04, desc = "游戏币不足"},
	no_login_room = add{code = 0x0d05, desc = "请先进入房间"},
	no_login_desk = add{code = 0x0d06, desc = "未进入游戏台"},
	desk_full = add{code = 0x0d07, desc = "游戏台已满"},
	desk_no_player = add{code = 0x0d08, desc = "玩家不在游戏台"},
	player_gaming = add{code = 0x0d09, desc = "玩家正在游戏"},
}

DESK_ERROR = {
	player_no_seat = add{code = 0x0e01, desc = "玩家未在坐位上"},
	game_has_begin = add{code = 0x0e02, desc = "游戏已经开始"},
	game_state_limit = add{code = 0x0e03, desc = "游戏状态限制"},
}


return errors