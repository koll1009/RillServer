local env = require "faci.env"

require "agent.agent_login"
require "agent.agent_room"


-- local modules = {}
-- local modules_arr = {}
-- local CMD = {}

-- --load agent 模块
-- local function load_agent_module()
--     local function register_module(name, pack)
--         modules[name] = require(pack)
--         table.insert(modules_arr,  modules[name])
--     end

--     register_module("proxy_mod", "agent_mod.agent_proxy")
--     -- register_module("login_mod", "agent_mod.login.login")

--     for _, mod in ipairs(modules_arr) do
--         if type(mod) == 'table' then
--             if mod.module_init then 
--                 mod.module_init()
--             end

--             if mod.register_event then 
--                 mod.register_event() 
--             end

--             if mod.register_handler then
--                 mod.register_handler() 
--             end

--             if mod.modules then 
--                 mod.modules(modules, modules_arr)
--             end

--             for k, v in pairs(mod.CMD or {}) do 
--                 CMD[k] = v 
--             end
--         end
--     end

--     collectgarbage('collect')
-- end
