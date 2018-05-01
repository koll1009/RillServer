local skynet = require "skynet"
local log = require "log"
local tool = require "tool"

local function testmysql()
    local mysql = require "mysqldb"
    local conf = {
        host = "127.0.0.1",
        port = "3306",
        database = "test",
        --user = "root",
        --password = "root"
    }
    assert(mysql.start(conf)) 

    local data = {
        id = 2,
        name = "test",
        key1 = "keyt2",
        tname = {
            k = "k",
            test = "test",
        }
    }
    mysql.replace("test", data)


    --data.id = 10
    --mysql.insert("test", data)


    data.name = "update"
    data.id = nil
    mysql.update("test", {id=1}, data)


    local ret = mysql.findOne("test", {id=1})
    log.debug("findOne ret: %s", tool.dump(ret))


    local ret = mysql.findOne("test", {name="test"}, {"id", "tname"})
    log.debug("findOne ret: %s", tool.dump(ret))

    local ret = mysql.find("test", {name="test"})
    log.debug("find ret: %s", tool.dump(ret))

    local ret = mysql.find("test", {name="test"}, {"id", "tname"})
    log.debug("find select ret: %s", tool.dump(ret))

    local ret = mysql.find("test", {name="itest"})
    log.debug("find ret: %s", tool.dump(ret))
end

skynet.start(function()
    log.debug("start test...")
    testmysql() 
    log.debug("end test...")
    --skynet.exit()
end)

