--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id client.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/11 16:25
 - @uses The robot client class.
--]]

local skynet = require 'skynet'
local socket = require 'skynet.socket'
local sprotoloader = require 'sprotoloader'
local log = require 'log'
local util = require 'util'

-- Other.
local require = require
local string = string
local assert = assert
local coroutine = coroutine
local print = print
local pcall = pcall

-- Data.
-------------------------------------------------------------------------------

local _M = {}
package.loaded[...] = _M
if setfenv and 'function' == type(setfenv) then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

handler = {} -- Msg handler.

local host
local sender
local threads= {}
local ret_msg = {}
local ret_err = {}

-- Local functions.
-------------------------------------------------------------------------------

-- Handle message.
local function handle_msg(self, type, name, response, f, args)
  local ok, r = pcall(f, self, args)
  if ok then
    if response then
      socket.write(self.fd, string.pack('>s2', response(r)))
    end
  else
    log:error('raise error: %s', r)
  end
end

-- Read message from socket.
local function read_msg(self)
  local fd = self.fd
  local s = socket.read(fd, 2)
  local msg, sz = nil, 0
  if s then
    sz = string.unpack('>H', s)
    msg = assert(socket.read(fd, sz), 'invalid fd ' .. fd)
  end
  return msg, sz
end

-- Package message.
local function pack_msg(t, data, session)
  local msg = sender(t, data, session)
  return string.pack('>s2', msg)
  --return msg:pack('>s2')
end

-- API.
-------------------------------------------------------------------------------


-- Dispatch socket message.
-- @param table self The socket table.
function dispatch(self)
  repeat
    local msg, sz = read_msg(self)
    if sz > 0 then
      local type, name, args, response = host:dispatch(msg, sz)
      if 'REQUEST' == type then
        local f = handler[name]
        if f then
          skynet.fork(handle_msg, self, type, name, response, f, args)
        end
      else
        local session, r, ud = name, args, response
        local co = threads[session]
        if not co then
          log:error('Invalid session: %s', session)
        else
          ret_msg[session] = r
          ret_err[session] = nil
          threads[session] = nil
          skynet.wakeup(co)
        end
      end
    else
      log('client close fd: %d', self.fd)
      self.fd = nil
      return self
    end
    if self.exit then
      log('client exit fd: %d', self.fd)
      return self
    end
  until false
end

-- Close socket.
-- @param table self The socket table.
function close(self)
  socket.close(self.fd)
end

-- Push message.
-- @param table self The socket table.
-- @param string name The package name.
-- @param table data The message data.
function push(self, name, data)
  if not self.fd then return end
  assert(socket.write(self.fd, pack_msg(name, data), 'closed ' .. self.fd))
end

-- Push fds.
function push_fds(fds, name, data)
  error('can\' call push_fds')
end

-- Request a message with a result.
-- @param table self The socket table.
-- @param number timeout Request timeout time.
-- @param string name Package name.
-- @param string name Package data.
-- @return table
function request(self, timeout, name, data)
  if not self.fd or socket.invalid(self.fd) then 
    return { e = -1 }
  end
  local session = skynet.genid()
  assert(
    socket.write(self.fd, pack_msg(name, data, session), 'closed ' .. self.fd))
  local co = coroutine.running()
  threads[session] = co
  skynet.timeout(timeout, function() 
    local co = threads[session]
    if not co then return end
    ret_msg[session] = string.format('timeout %d, %s', self.fd or 0, name)
    ret_err[session] = true
    threads[session] = nil
    skynet.wakeup(co)
  end)
  skynet.wait()
  local err = ret_err[session]
  local r = ret_msg[session]
  ret_err[session], ret_msg[session] = nil, nil
  if err then
    return { e = -1 }
  end
  return r
end

-- Init.
function _M.init(s, c)
  local sprotoloader = require 'sprotoloader'
  local proto_loader = skynet.uniqueservice 'proto_loader'
  local slot_s = skynet.call(proto_loader, 'lua', 'index', s)
  host = sprotoloader.load(slot_s):host 'package'
  local slot_c = skynet.call(proto_loader, 'lua', 'index', c)
  sender = host:attach(sprotoloader.load(slot_c))
end
