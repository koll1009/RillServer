-- local skynet = require "skynet"
-- local queue = require "skynet.queue"
-- local cs = queue()
-- local libcenter = require "libcenter"
-- local libsocket = require "libsocket"



local name, id = ...
local s = require "faci.service"
s.init(name, id)

-- skynet.start(function()
--     init()
--     if env.init then
--         env.init()
--     end

--     -- If you want to fork a work thread , you MUST do it in CMD.login
-- 	skynet.dispatch("lua",function(_, _, cmd, ...)
--         local f = assert(CMD[cmd], cmd)
--         skynet.retpack(cs(f, ...))
-- 	end)
-- end)

