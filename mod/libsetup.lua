local skynet = require "skynet"
local builder = require "skynet.datasheet.builder"
local datasheet = require "skynet.datasheet"
local log = require "log"

local M = {}

function M.get(t, v)
    local conf = datasheet.query(t)
    if not conf then
        return
    end
    return conf[v]
end

setmetatable(M, {
    __index = function(t, k)
        return datasheet.query(k)
    end
})

return M


