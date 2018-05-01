-- 平台参数配置

local M = {}

M.uc = {
    cpId = 30394,
    gameId = 739808,
    apiKey = "800f0f03bd9af651c871eb0ec3f43109",
    --auth_path = "sdk.test4.9game.cn",
    auth_path = "sdk.9game.cn",
    auth_url = "/cp/account.verifySession",
}

M.guopan = {
	appid = 108312,
	apiKey = "QBD66SGZ8U4ILDB3M6YU60FMC4PQ8QJC9MNEPVSDTZED0S2XADBTGQ80OPYJXWLJCLIENT SECRET KEY：JMH029Z9E3IX5YRO";
	auth_path = "userapi.guopan.cn",
	auth_url = "/gamesdk/verify/"
}

M.ccplay = {
    auth_path = "android-api.ccplay.cc",
    auth_url = "/api/v2/payment/checkUser"
}

return M
