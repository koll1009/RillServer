local skynet = require "skynet"
local builder = require "skynet.datasheet.builder"
local datasheet = require "skynet.datasheet"
local log = require "log"
local faci = require "faci.module"
local lfstool = require "lfstool"

local module = faci.get_module("setup")
local dispatch = module.dispatch
local forward = module.forward
local event = module.event


local function update()
    skynet.timeout(100, 
        function() 
            D.update_all()  
            update()
        end )
end

local function dir(path)
    local ret = {}
	lfstool.attrdir(path, function(file)
	    local f = string.match(file, "(%w+)%.lua")
		
        if f then
            table.insert(ret, f)
        end
	end)
    return ret
end

local reload = require "reload"
local function init()
    local list = dir("config")
    for k, v in pairs(list) do
        DEBUG("init " .. v .. " conf")
        local conf = reload.loadmod(v)
        builder.new(v, conf)
    end
end


function dispatch.update_all()
	list = dir("config")
	for k, v in pairs(list) do
		DEBUG("update " .. v .. " conf")
		dispatch.update(v)
	end
end

function dispatch.update(name)
	datasheet.query(name) --ȷ������
	local conf = reload.loadmod(name)
	builder.update(name, conf)
	builder.update(name, conf)
	DEBUG("update conf: " .. name)
end

skynet.init(init)