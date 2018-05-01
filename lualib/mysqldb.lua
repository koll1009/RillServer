local skynet = require "skynet"
local mysql = require "mysql"
local log = require "log"
local json = require "cjson"
local tool = require "tool"

local mysqldb = {}
mysqldb.__index = mysqldb

function mysqldb:start(conf)
    local host = conf.host
    local port = conf.port
    local database = conf.database
    local user = conf.user
    local password = conf.password

	local function on_connect(db)
		db:query("set charset utf8");
	end
	
	local db = mysql.connect({
		host = host,
		port = port,
		database = database,
		user = user,
		password = password,
		max_packet_size = 1024 * 1024,
		on_connect = on_connect
	})
	if not db then
		log.error("failed to connect conf: %s", tool.dump(conf))
		assert(nil)
        return nil
	end
	log.debug("mysql success to connect to mysql server")
	
	local o = {db = db, table_desc={}}
	setmetatable(o, mysqldb)
    return o
end

function mysqldb:get_table_desc(cname)
	local table_desc = self.table_desc
	local db = self.db
	
    local desc = table_desc[cname]
    if desc then
        return desc
    end

    local sql = string.format("desc %s", cname)
    local ret = db:query(sql)

    if ret.errno then
        log.error("desc ret: %s, sql: %s", tool.dump(ret), sql)
        return
    end

    log.error("desc ret: %s", tool.dump(ret))
    desc = {}
    for k, v in pairs(ret) do
        desc[v.Field] = string.match(v.Type, "(%w+)%(%w+%)")
    end

    log.error("desc : %s", tool.dump(desc))
    table_desc[cname] = desc
    return ret
end

local function build_selector(selector)
    local t = {}     
    for k, v in pairs(selector) do
        if type(k) == "string" then
            if type(v) == "string" then
                table.insert(t, string.format("%s = %s", k, mysql.quote_sql_str(v)))
            elseif type(v) == "number" then
                table.insert(t, string.format("%s = %d", k, v))
            end
        end
    end
    local str = table.concat(t, ",")
    return str
end

local function build_field_selector(field_selector)
    if not field_selector then
        return "*"
    end

    local str = table.concat(field_selector, ",") 
    return str
end

function mysqldb:build_find_data(cname, data)
    local desc = self:get_table_desc(cname)
    if not desc then
        return
    end

    for k, v in pairs(desc) do
        if v == "varchar" then
            for kk, vv in pairs(data) do
                local str = vv[k]
                if str then
                    local t = json.decode(str)
                    vv[k] = t
                end
            end
        end
    end
    return data
end

----以下是对外接口

function mysqldb:findOne(cname, selector, field_selector)
	local table_desc = self.table_desc
	local db = self.db
	
    local selector_str = build_selector(selector)
    local field_selector_str = build_field_selector(field_selector)

    local sql = string.format("select %s from %s where %s limit 1", field_selector_str, cname, selector_str)
    log.debug("sql: %s", sql)
    local ret = db:query(sql)

    log.debug("=-==ret: %s", tool.dump(ret))
    ret = self:build_find_data(cname, ret)
    return ret and ret[1] or nil
end

function mysqldb:find(cname, selector, field_selector)
	local table_desc = self.table_desc
	local db = self.db
	
    local selector_str = build_selector(selector)
    local field_selector_str = build_field_selector(field_selector)

    local sql = string.format("select %s from %s where %s", field_selector_str, cname, selector_str)
    local ret = db:query(sql)
    log.debug("=-==ret: %s", tool.dump(ret) .. " sql: " .. sql)
    ret = self:build_find_data(cname, ret)
    return ret
end

function mysqldb:alter(cname, selector)
	local table_desc = self.table_desc
	local db = self.db
	
    local desc = self:get_table_desc(cname)
    if not desc then
        return
    end

    local t = nil
    for k, v in pairs(selector) do
         if type(k) == "string" then
            if not desc[k] then
                t = t or {}
                if type(v) == "string" then
                    table.insert(t, string.format("add %s CHAR(100)", k))
                elseif type(v) == "number" then
                    table.insert(t, string.format("add %s INT", k))
                elseif type(v) == "table" then
                    table.insert(t, string.format("add %s VARCHAR(1024)", k))
                end
            end
        end
    end
    if not t then
        return
    end

    local str = table.concat(t, ",")
    local sql = string.format("alter table %s %s", cname, str)
    log.debug("sql: " .. sql)
    local ret = db:query(sql)
    log.debug("alter ret: " .. tool.dump(ret))
    return ret
end


function mysqldb:update(cname, selector, field_selector, upsert)
	local table_desc = self.table_desc
	local db = self.db
	
    self:alter(cname, selector)

    local selector_str = build_selector(selector)
    local field_selector_str = build_selector(field_selector)

    local sql = string.format("update %s set %s where %s", cname, field_selector_str, selector_str)
    log.debug("sql: " .. sql)
    local ret = db:query(sql)
    log.debug("update ret: " .. tool.dump(ret))
	
	if upsert and err.affected_rows == 0 then
		return self:insert(cname, field_selector)
	end
    return ret
end

local function build_insert_data(data)
    local field = {}
    local value = {}
    for k, v in pairs(data) do
        if type(k) == "string" then
            table.insert(field, k)
        end

        if type(v) == "string" then
            table.insert(value, string.format("%s", mysql.quote_sql_str(v)))
        elseif type(v) == "number" then
            table.insert(value, v)
        elseif type(v) == "table" then
            local str = json.encode(v)
            table.insert(value, string.format("%s", mysql.quote_sql_str(str)))
        end
    end
    local field_str = table.concat(field, ",")
    local value_str = table.concat(value, ",")
    return field_str, value_str
end

function mysqldb:create_table(cname, data)
	local table_desc = self.table_desc
	local db = self.db
	
    assert(type(data) == "table")

    local t = {}
 
    for k, v in pairs(data) do
       if type(v) == "string" then
           table.insert(t, string.format("%s blob NOT NULL", k)) --必要时改char(100)
       elseif type(v) == "number" then
           table.insert(t, string.format("%s int", k))
       elseif type(v) == "table" then
           table.insert(t, string.format("%s varchar(1024)", k))
       end
    end
	
	if data.playerid then
        table.insert(t, "PRIMARY KEY(playerid)")
    end
	
    if not data.playerid and not data.id  then
        table.insert(t, "id INT NOT NULL AUTO_INCREMENT")
		table.insert(t, "PRIMARY KEY(id)")
    end

    
    local str = table.concat(t, ",")

    local sql = string.format("create table if not exists %s(%s)ENGINE=InnoDB DEFAULT CHARSET=utf8;",cname,str)

    log.debug("sql: " .. sql)

    local ret = db:query(sql)

    log.debug("create table ret: " .. tool.dump(ret))
    return ret
end

function mysqldb:insert(cname, data)
	local table_desc = self.table_desc
	local db = self.db
	
    if not self:get_table_desc(cname) then
        self:create_table(cname, data)
    end

    local field_str, value_str = build_insert_data(data)
    local sql = string.format("insert into %s(%s)values(%s)", cname, field_str, value_str)
    log.debug("sql: %s", sql)
    local ret = db:query(sql)
    log.debug("ret: %s", tool.dump(ret))
    return ret
end

function mysqldb:replace(cname, data)
	local table_desc = self.table_desc
	local db = self.db
	
    if not get_table_desc(cname) then
        self:create_table(cname, data)
    end


    self:alter(cname, data)

    local field_str, value_str = self:build_insert_data(data)
    local sql = string.format("replace into %s(%s)values(%s)", cname, field_str, value_str)
    log.debug("sql: " .. sql)
    local ret = db:query(sql)

    log.debug("ret: " .. tool.dump(ret))
    return ret
end

function mysqldb:delete(cname, selector)
	local table_desc = self.table_desc
	local db = self.db
	
    local selector_str = build_selector(selector)
    local sql = string.format("delete from %s where %s", cname, selector_str)
    local ret = db:query(sql)
    return sql
end

return mysqldb


