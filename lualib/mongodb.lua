local skynet = require "skynet"
local mongo = require "mongo"
local bson = require "bson" 
local log = require "log"
local tool = require "tool"


local mongodb = {}
mongodb.__index = mongodb

function mongodb:start(conf)
    local host = conf.host
    local db_name = conf.db_name
    local db_client = mongo.client({host = host})
    local db = db_client[db_name]
	
	local o = {db = db}
	setmetatable(o, mongodb)
	return o
end

function mongodb:findOne(cname, selector, field_selector)
    local db = self.db
	return db[cname]:findOne(selector, field_selector)
end

function mongodb:find(cname, selector, field_selector)
	local db = self.db
	return db[cname]:find(selector, field_selector)
end

local function db_help(db, cmd, cname, ...)
    local c = db[cname]
    c[cmd](c, ...)
    local r = db:runCommand('getLastError')
    local ok = r and r.ok == 1 and r.err == bson.null
    if not ok then
        skynet.error(v.." failed: ", r.err, tname, ...)
    end
    return ok, r.err   
end

function mongodb:update(cname, selector, update, upsert)
	local db = self.db
	local collection = db[cname]
	
	collection:update(selector, update, upsert)
	local r = db:runCommand("getLastError")
    if r.err ~= bson.null then
        ERROR("mongodb update error-> ", cname, " selector ", selector, " err:", r.err)
		return false, r.err
	end

    if r.n <= 0 then
        ERROR("mongodb update-> ", cname, " selector ", selector, " failed")
    end

    DEBUG("=======mongodb update finish ", cname, " selecto-> ", r.n,  "========")
	return true, r.err
end

function mongodb:insert(cname, data)
	local db = self.db
    return db_help(db, "safe_insert", cname, data)
end

function mongodb:delete(cname, selector)
	local db = self.db
    return db_help(db, "delete", cname, selector)
end

function mongodb:incr(key)
	local db = self.db
    local cname = "tb_key"
    local ret = self:findOne(cname, {key=key})
    local id = 0
    if ret then
        id = ret.uuid
    end
    id = id + 1
    ret = self:update(cname, {key=key}, {key=key, uuid=id}, true)
	assert(ret)
    assert(id)
    return id
end

return mongodb









