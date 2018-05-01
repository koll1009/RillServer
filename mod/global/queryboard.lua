local skynet = require "skynet"
local libdbproxy = require "libdbproxy"

local faci = require "faci.module"
local module = faci.get_module("queryboard")
local dispatch = module.dispatch
local forward = module.forward
local event = module.event

--���а�

local cache = nil
--cache = {
--	name = "queryboard"
--	t = {
--		[uid] = count
--	}
--	_id = xxx
--}

local function loaddata()
	if cache then
		return
	end
	local c = libdbproxy.get_globaldata("ranklist", "queryboard")
	cache = cache or {
		name = "queryboard",
		t = {},
		_id = c and c.id or nil
	} 
	--tonum
	for i, v in pairs(c and c.t or {}) do
		cache.t[tonumber(i)] = v
	end
end


local function savedata()
	libdbproxy.set_globaldata("ranklist", "queryboard", cache)
	return true
end


local function sortdata()
	local s = {}
	for i, v in pairs(cache.t) do
		local t = {uid=i, count=v}
		table.insert(s, t)
	end
	table.sort(s,function(a, b) 
				return a.count > b.count
			end)
	return s
end

function dispatch.query(uid)
	loaddata()
	local t = cache.t
	t[uid] = t[uid] or 0
	t[uid] = t[uid] + 1
	--ʵ��ӦΪ��ʱ����͹ط�ʱ����
	savedata()
	return {msg="queryboard", s=sortdata()}
end