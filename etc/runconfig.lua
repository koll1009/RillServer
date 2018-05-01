return {
    TEST = true,
    version = "1.0.0",
	--集群地址配置
	cluster = {
		admin = "127.0.0.1:2527", --后台交互节点

		node1 = "127.0.0.1:2528", 
		node2 = "127.0.0.1:2529",
	},
	--通信协议
	prototype = "ws",  --tcp/ws
	protopack = "json",   --pb/json

	--各个服务配置
	service = {
		--debug_console服务
		debug_console = {
			[1] = {port=10701, node = "node1"},
			[2] = {port=10702, node = "node2"},
			[3] = {port=10703, node = "admin"},
		},
		--game服务
		game = {
			[1] = {node = "node1"},
			[2] = {node = "node2"},
		},

		agentpool_common = {maxnum = 10, recyremove = 1, brokecachelen = 1,}, 
		agentpool = {
			[1] = {node = "node1"},
			[2] = {node = "node2"},
		},
		--gateway服务
		gateway_common = {maxclient = 1024, nodelay = true},
		gateway = {
			[1] = {port = 11798,  node = "node1"},
			[2] = {port = 11799,  node = "node2"},
		},
		--global服务
		global = {
			[1] = {node = "node1"},
			[2] = {node = "node1"},
		},
		--center服务
		center = {
			[1] = {node = "node1"},
			[2] = {node = "node1"},
		},
		--login服务
		login = {
			[1] = {node = "node1"},
			[2] = {node = "node2"},
		},
		--dbproxy服务
		dbproxy_common = {
			accountdb = {db_type = "mongodb", host = "127.0.0.1", db_name = "account"}, --host,port,username,password,authmod
			gamedb = {db_type = "mongodb", host = "127.0.0.1", db_name = "game"},
			globaldb = {db_type = "mongodb", host = "127.0.0.1", db_name = "global"},
			logdb = {db_type = "mongodb", host = "127.0.0.1", db_name = "log"},
		},
		dbproxy = {
			[1] = {node = "node1"},
			[2] = {node = "node1"},
		},
		--host服务
		host_common = {
			web 	= 	{node = "node1", port = 12111},
			console = 	{node = "node1", port = 12002}, --尚未实现
		}
    },
	--玩家数据表配置
	playerdata = {
		baseinfo = true,
	},
	--支持的游戏类型 及对应的入口文件
	games_common = {
		move = "libmove",  
	},

	--具体各个功能逻辑的配置
	movegame = {
		global = {
			[1] = "global1",
			[2] = "global2",
		},
	},
	queryboard = {
		global = {
			[1] = "global1",
			--不支持分布式
		},
	},

	lifegame = {
		global = {
			[1] = "global1",
			[2] = "global1",
		},
		mgr = "global1",
	},
	
}
