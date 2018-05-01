local skynet = require "skynet"
local runconf = require(skynet.getenv("runconfig"))
local prototype = runconf.prototype
local protopack = runconf.protopack

return require("libsocket_"..prototype)