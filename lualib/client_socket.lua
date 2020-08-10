--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id client_socket.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/03 19:56
 - @uses The simple client socket.
--]]

local client = require 'client'
local socket = 'skynet.socket'

-- Read a message by table.
-- @param table self The socket table.
-- @return mixed
function client.read_message(self)
  local fd = self.fd
  if socket.invalid(fd) then
    return
  end
  local s = socket.read(fd, 2)
  if not s then
    return
  end
  local len = s:unpack('>H')
  return socket.read(fd, len), len
end
-- Start read a socket.
-- @param table self The socket table
-- @param mixed on_warning
function client.start(self, on_warning)
  socket.start(self.fd)
  socket.warning(self.fd, on_warning)
end

return client
