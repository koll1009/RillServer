local socket = require "socket"
local tcplib = {}

function tcplib.send(fd, data)
	socket.write(fd, data)
end

return tcplib