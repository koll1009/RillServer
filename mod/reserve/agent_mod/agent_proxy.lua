local skynet = require "skynet"
local player_px = require "module.player_px"

local M = { }
local m_player

M.CMD = {}

function M.CMD.proxy_module_call(mods, f, ...)
    return m_player:call(mods, f, ...)
end


--- 玩家上线时从cache服务获取自己的数据
function M.playerOnline()
    if m_player then return m_player end

    m_player = player_px()
    m_player:_initalize()
    m_player:_connectMod()
    local datas = m_player:_loadDB(info.uin)

    assert(datas, info.uin)
    pcall(m_player._initData, m_player, info.uin, datas)
    m_player:_delayInit()

    return m_player
end

function M.module_init()
end

function M.on_player_init()
end

function M.on_player_leave()
    if m_player then
        m_player:checkSaveDB()
    end
end

local localTime = os.time()
function M.update(lastTime, now)
    if now - localTime >=30 then
        localTime = now
        if m_player then
            m_player:checkSaveDB()
        end
    end
end

return M
