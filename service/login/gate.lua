--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id gate.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/04 16:37
 - @uses The gate service.
--]]

local skynet = require 'skynet'
local socket = require 'skynet.socket'
local socketdriver = require 'skynet.socketdriver'
local service_provider = require 'service_provider'
local cluster = require 'skynet.cluster'
local log = require 'log'

-- Data.
-------------------------------------------------------------------------------

local _M = {}
local data = { socket = {} }
local auths = {}
local auth_index = 0

-- Local functions.
-------------------------------------------------------------------------------

local function auth_socket(auth, fd, addr)
  return skynet.call(auth, 'lua', 'auth', fd, addr)
end

local function new_socket(fd, addr)
  data.socket[fd] = '[AUTH]'
  auth_index = auth_index + 1
  if auth_index > #auths then
    auth_index = 1
  end
  local auth = auths[auth_index]
  log:info('accept %d(%s) dispatch: [:%08x]', fd, addr, auth)
  local ok, err = auth_socket(auth, fd, addr)
  if not ok then
    log:warn(err)
  end
  data.socket[fd] = nil
  socketdriver.close(fd)
end

-- API.
-------------------------------------------------------------------------------

-- Open the gate(server listen).
-- @param mixed ip Listen ip.
-- @param number port Listen port.
-- @param table auths The auth service list.
function _M.open(ip, port, _auths)
  print('ip prot, _auths', ip, port, _auths)
  assert(data.fd == nil, 'Already open')
  auths = _auths
  data.fd = socket.listen(ip, port)
  data.ip = ip
  data.port = port
  socket.start(data.fd, new_socket)
  log:info('open %s:%d', ip, port)
end

-- Close the gate.
function _M.close()
  assert(data.fd)
  log:info('close %s:%d', data.ip, data.port)
  socket.close(data.fd)
  data.fd = nil
  data.ip = nil
  data.port = nil
end

return {
  command = _M,
  info = data,
  release = function()
    if data.fd then
      _M.close()
    end
  end
}
