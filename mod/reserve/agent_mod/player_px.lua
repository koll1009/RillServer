-- 玩家数据逻辑总代理
-- 管理所有代理的基础代理
local proxy  = require "agent_mod.proxy_base"

local M = {}
proxy(M)

local hero          = require "agent_mod.login.login_px"


function M:reg_mod()
    self:registerModule("hero"         , hero)
end

function M:connectMod()
end


return M
