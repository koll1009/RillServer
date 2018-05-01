local skynet = require "skynet"
local tool = require "tool"


local service_map = {}

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,	-- PTYPE_CLIENT = 3
	unpack = function() end,
	dispatch = function(_, address)
        print("======= exit address: " .. address .. " service: " .. tool.dump(service_map))
		local w = service_map[address]
		if w then
			for watcher in pairs(w) do
                print("=== watcher: " .. watcher)
				skynet.redirect(watcher, address, "error", 0, "")
			end
			service_map[address] = false
		end
	end
}

local function monitor(session, watcher, command, service)
	assert(command, "WATCH")
    print("====== command: " .. command)

	local w = service_map[service]
	if not w then
		if w == false then
			skynet.ret(skynet.pack(false))
			return
		end
		w = {}
		service_map[service] = w
	end
	w[watcher] = true
	skynet.ret(skynet.pack(true))
end

skynet.start(function()
	skynet.dispatch("lua", monitor)
end)

