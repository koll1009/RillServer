local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local tool = require "tool"

local faci = require "faci.module"
local module = faci.get_module("web")
local dispatch = module.dispatch
local forward = module.forward
local event = module.event

local runconf = require(skynet.getenv("runconfig"))
local node = skynet.getenv("nodename")

local default_page = [[
	<p>
	hehe
	<p>
	<a href="/?cmd=web.test">test</a>
	<p>
	<a href="http://www.pal5h.com">pal5h</a>
	<p>
	<a href="/?cmd=web.kill">kill</a>
	<p>
	<a href="/?cmd=stop.stop">stop all</a>
]]

--http://123.207.111.118:8111/?cmd=web.test
function dispatch.test()
	return "good man"
end

local function response(id, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		log.info("fd = %d, %s", id, err)
	end
end

local function handler(addr, fd)
	socket.start(fd)
	-- limit request body size to 8192 (you can pass nil to unlimit)
	local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(fd), 8192)
	
	if not code then
		socket.close(fd)
		return
	end
	
	if code ~= 200 then  -- 服务器成功返回网页
		response(fd, code)
		socket.close(fd)
		return
	end
	
	local path, query = urllib.parse(url)
	if not query then 
		response(fd, code, default_page)
		socket.close(fd)
		return
	end
	
	local q = urllib.parse_query(query)
	if not q.cmd then
		response(fd, code, default_page)
		socket.close(fd)
		return
	end

	local ret = skynet.call(skynet:self(), "lua", q.cmd , addr, fd, q)
	ret = ret or "nil response"
	response(fd, code, ret)
	socket.close(fd)
end

function event.start()
	local cfg = runconf.service.host_common.web
	if node ~= cfg.node then
		return
	end
	
	local listenfd = socket.listen("0.0.0.0", cfg.port)
	log.info("Listen web port %d", cfg.port)
	
	socket.start(listenfd , function(fd, addr)
		log.info("connected %s%d", addr, fd)
		skynet.fork(handler, addr, fd)
	end)
end
