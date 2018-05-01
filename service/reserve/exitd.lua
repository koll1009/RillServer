local skynet = require "skynet"

local function init()

	--return skynet.call(".launcher", "lua", "LIST")
    local addr = skynet.queryservice("testd")

    print("==== 8888 1000 === p: " .. addr)
    local ok, ret = pcall(skynet.call, addr, "debug", "LINK")
    if not ok then
        print(ok)
        print(ret)
    end
    print("1111 ==== 21000 ===")
end

skynet.start(function()
    init() 
end)
