local skynet = require "skynet"
local json = require "cjson"
local log = require "log"
local pb = require("luapbintf")
local io = require "io" 
local crc32 = require "crc32" 
local tool = require "tool"
local lfstool = require "lfstool"

--协议号映射表
local name2code = {}
local code2name = {}

--分析proto文件，计算映射表
local function analysis_file(path)
	local file = io.open(path, "r") 
	local package = ""
	
	for line in file:lines() do
		local s, c = string.gsub(line, "^%s*package%s*([%w%.]+).*$", "%1")
		if c > 0 then
			package = s
		end
		local s, c = string.gsub(line, "^%s*message%s*([%w%.]+).*$", "%1")
		if c > 0 then
			local name = package.."."..s
			local code = crc32.hash(name)
			--print(string.format("analysis proto file:%s->%d(%x)", name, code, code))
			name2code[name] = code
			code2name[code] = name
		end
	end
	file:close()  
end

--导入proto文件，并analysis_file
local path = skynet.getenv("app_root").."proto"
pb.add_proto_path(path)
lfstool.attrdir(path, function(file)
	local file = string.match(file, path.."/(.+%.proto)") --获取文件名
	if file then
		--log.info("import proto file:"..file)
		pb.import_proto_file(file) --相对路径
		analysis_file(path.."/"..file) --绝对路径
	end
end)

--打印二进制string，用于调试
local function bin2hex(s)
    s=string.gsub(s, "(.)", function (x) return string.format("%02X ", string.byte(x)) end)
    return s
end

local M = {}

--cmd:login.Login
--checkcode:1234
--msg:{account="1",password="1234"}
function M.pack(cmd, check, msg)
	--格式说明
	--> >:big endian
	-->i2:前面两位为长度
	-->i4:int32 checkcode
    -->I4:uint32 cmd_code 
	
	--code
	local code = name2code[cmd]
	if not code then
		log.error(string.format("protopack_pb fail, cmd:%s", cmd or "nil"))
		return
	end
	--check
	check = check or 0
	--pbstr
	local pbstr = pb.encode(cmd, msg)
	local pblen = string.len(pbstr)
	--len
	local len = 4+4+pblen
	--组成发送字符串
	local f = string.format("> i2 i4 I4 c%d", pblen)
	local str = string.pack(f, len, check, code, pbstr)
	--调试
	--log.info("send:"..bin2hex(str))
	log.info(string.format("send:cmd(%s) check(%d) msg->%s", cmd, check, tool.dump(msg)))
    return str
end

function M.unpack(str)
	log.info("recv:"..bin2hex(str))
	local pblen = string.len(str)-4-4
	local f = string.format("> i4 I4 c%d", pblen)
	local check, code, pbstr = string.unpack(f, str)
	log.info("recv pbstr:"..bin2hex(pbstr))
	local cmd = code2name[code]
	if not cmd then
		log.info("recv:code(%d) but not regiest", code)
		return 
	end
	local msg = pb.decode(cmd, pbstr)
	
	log.info("recv:cmd(%s) check(%d) msg->%s", cmd, check, tool.dump(msg))
    return cmd, check, msg
end

return M


