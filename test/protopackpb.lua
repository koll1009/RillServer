
local json = require "cjson"
local pb = require("luapbintf")
local io = require "io" 
local crc32 = require "crc32" 
local tool = require "tool"
local lfstool = require "lfstool"
local lfs = require "lfs"

--Э?????
local name2code = {}
local code2name = {}

--??protoτ?ì?????
local function analysis_file(path)
	local file = io.open(path, "r") 
	local package = ""
	
	for line in file:lines() do
		local s, c = string.gsub(line, "^%s*package%s*([^%s]+)%s*[;%s].*$", "%1")
		if c > 0 then
			package = s
		end
		local s, c = string.gsub(line, "^%s*message%s*([^%s]+)%s*[{%s].*$", "%1")
		if c > 0 then
			local name = package.."."..s
			local code = crc32.hash(name)
			print(string.format("analysis proto file:%s->%d(%x)", name, code, code))
			name2code[name] = code
			code2name[code] = name
		end
	end
	file:close()  
end

--??protoτ?ì?analysis_file

local path = lfs.currentdir()  --eg /root/zServer/test
pbpath = string.sub(path, 1, -5).."proto"  --eg /root/zServer/proto

pb.add_proto_path("/")

lfstool.attrdir(pbpath, function(file)
	local file = string.match(file, "(.+%.proto)")
	if file then
		print("import proto file:"..file)
		pb.import_proto_file(string.sub(file,2))
		analysis_file(file)
	end
end)

--?????stringì????
local function bin2hex(s)
    s=string.gsub(s,"(.)",function (x) return string.format("%02X ",string.byte(x)) end)
    return s
end

local M = {}

--cmd:login.Login
--checkcode:1234
--msg:{account="1",password="1234"}
function M.pack(cmd, check, msg)
	--????
	--> >:big endian
	-->i2:??}λ???
	-->i4:int32 checkcode
    -->I4:uint32 cmd_code 
	
	--code
	local code = name2code[cmd]
	if not code then
		print(string.format("protopack_pb fail, cmd:%s", cmd or "nil"))
		return
	end
	print("pack code:"..code)
	--check
	check = check or 0
	--pbstr
	local pbstr = pb.encode(cmd, msg)
	local pblen = string.len(pbstr)
	--len
	local len = 4+4+pblen
	--???????
	local f = string.format("> i2 i4 I4 c%d", pblen)
	local str = string.pack(f, len, check, code, pbstr)
	--??
	print("send pbstr:"..bin2hex(pbstr))
	print("send:"..bin2hex(str))
	print(string.format("send:cmd(%s) check(%d) msg->%s", cmd, check, tool.dump(msg)))
    return str
end

function M.unpack(str)
	local pblen = string.len(str)-4-4
	local f = string.format("> i4 I4 c%d", pblen)
	local check, code, pbstr = string.unpack(f, str)
	local cmd = code2name[code]
	local msg = pb.decode(cmd, pbstr)
	--print("recv:"..bin2hex(str))
	--print("recv pbstr:"..bin2hex(pbstr))
	print(string.format("recv:cmd(%s) check(%d) msg->%s", cmd, check, tool.dump(msg)))
    return cmd, check, msg
end




return M


