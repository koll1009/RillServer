local socket = require "socket"
local wslib = {}
--默认fin和mask
function wslib:send_frame(fd, opcode, data)
    local finbit, mask_bit = 0x80,0
   -- if fin then finbit = 0x80 else finbit = 0 end
   -- if self.mask_outgoing then mask_bit = 0x80 else mask_bit = 0 end
    local frame = string.pack("B", finbit | opcode)
    local len = #data
    if len < 126 then
        frame = frame .. string.pack("B", len | mask_bit)
    elseif len < 0xFFFF then
        frame = frame .. string.pack(">BH", 126 | mask_bit, len)
    else 
        frame = frame .. string.pack(">BL", 127 | mask_bit, len)
    end
    frame = frame .. data
    socket.write(fd, frame)
end

function wslib:send_text(fd,data)
    self:send_frame(fd, 0x1, data)
end

function wslib:send_binary(fd,data)
    self:send_frame(fd, 0x2, data)
end

function wslib:send_ping(fd,data)
    self:send_frame(fd, 0x9, data)
end

function wslib:send_pong(fd,data)
    self:send_frame(fd, 0xA, data)
end

function wslib:close(fd,code, reason)
    if code == nil and reason ~= nil then
        code = 1000
    end
    local data = ""
    if code ~= nil then
        data = string.pack(">H", code)
    end
    if reason ~= nil then
        data = data .. reason
    end
    self:send_frame(fd, 0x8, data)
end

--即为sendtext
function wslib.send(fd, data)
	wslib:send_text(fd, data)
end

return wslib
