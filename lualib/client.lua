--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id client.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/03 20:02
 - @uses The socket client class.
--]]

local skynet = require 'skynet'
local cluster = require 'skynet.cluster'
local socketdriver = require 'skynet.socketdriver'
local trace = require 'trace.c'
local server = require 'server'
local attach_info = require 'attach_info'
local log = require 'log'

-- Data.
-------------------------------------------------------------------------------

local thread = thread or {}
local ret_msg = ret_msg or {}
local ret_err = ret_err or {}
local host = host or nil
local sender = sender or nil

local traceback = trace.traceback

local _M = {}
local handler = {}

-- Local functions.
-------------------------------------------------------------------------------

-- Forward message to map service.
-- @param table self The socket table.
-- @param string name The message name.
-- @param function response The response function.
-- @param mixed args
local function forward_msg(self, name, response, args)
  local start_t = skynet.now()
  local f = server.send_map
  if response then
    f = server.call_map
  end
  local ok, r = xpcall(f, traceback, self, name, self.rid, args)
  if ok then
    if response then
      local msg = response(r):pack('>s2')
      if not socketdriver.send(self.fd, msg) then
        log:warn('forward_msg response msg[%s] failed')
      end
    end
  else
    log:warn('forward_msg fd[%d] msg[%s] handle raise error: %s', 
              self.fd, name, r)
  end
  local use_t = skynet.now() - start_t
  if use_t > 10 then
    log:debug('forward_msg fd[%d] msg[%s] use time: %d', self.fd, name, use_t)
  end
end

-- Handle one message.
-- @param table self The socket table.
-- @param string name The message name.
-- @param function response The response function.
-- @param function f The handle function.
-- @param mixed args
local function handle_msg(self, name, response, f, args)
  local start_t = skynet.now()
  local ok, r = xpcall(f, traceback, self, args)
  if ok then
    if response then
      if type(r) ~= 'table' then
        log:warn('handle_msg fd[%d] msg[%s] response error', self.fd, name)
      else
        if r.e and type(r.e) ~= 'number' then
          log:warn('handle_msg fd[%d] msg[%s] response error', self.fd, name)
        end
        local msg = response(r):pack('>s2')
        if not socketdriver.send(self.fd, msg) then
          log:warn('handle_msg fd[%d] msg[%s] response failed', self.fd, name)
        end
      end
    end
  else
    log:warn('handle_msg fd[%d] msg[%s] raise error', self.fd, name)
  end
  local use_t = skynet.now() - start_t
  if use_t > 10 then
    log:debug('handle_msg fd[%d] msg[%s] use time: %d', self.fd, name, use_t)
  end
end

local print_ignores = {
  ['move'] = 1,
}

local function print_m(name, str)
  if not server.print_log then return end
  if print_ignores[name] then return end
  log:debug('%s %s', str, name)
end

-- API.
-------------------------------------------------------------------------------

function _M.handler()
  return handler
end

-- Dispatch recv messages.
-- @param table self The socket table.
-- @param table msg The msg table.
-- @param number sz The msg size.
-- @param mixed lock Lock function.
function _M.dispatch(self, msg, sz, lock)
  local tp, name, args, response = host:dispatch(msg, sz)
  print_m(name, 'recv <<<')
  if 'REQUEST' == tp then
    local f = handler[name]
    if f then
      if lock then
        lock(handle_msg, self, name, response, f, args)
      else
        handle_msg(self, name, response, f, args)
      end
    else
      if handler['forward'] then -- To forward.
        local s = handler['forward'](self)
        if s then
          forward_msg(self, name, response, msg)
        else
          log:warn('dispatch invalid the target service: %s', name)
        end
      else
        log:warn('dispatch invalid forward is nil: %s', name)
      end
    end
  else
    local session, r, ud = name, args, response
    local co = threads[session]
    if not co then
      log:warn('dispatch invalid session: %s', session)
    else
      ret_msg[session] = r
      threads[session] = nil
      ret_err[session] = nil
      socket.wakeup(co)
    end
  end
  if self.quit then
      self.response()(self)
  end
end

-- Dispatch special.
-- @param table self The socket table.
-- @param string sp_name The special message name.
-- @param table msg The message table.
-- @param number sz The message size.
function _M.dispatch_special(self, sp_name, msg, sz)
  local tp, name, args, response = host:dispatch(msg, sz)
  print_m(name, 'recv <<<')
  assert('REQUEST' == tp, 'need message ' .. sp_name)
  assert(name == sp_name, 'need message '.. sp_name)
  local f = handler[name]
  handle_msg(self, name, response, f, args)
end

-- Push one message.
-- @param table The socket table.
-- @param string name
-- @param table data
function _M.push(self, name, data)
  _M.push_fd(self.rid, self.fd, name, data)
end

-- Push one message to fd.
-- @param string rid The role id.
-- @param number fd
-- @param string name
-- @param table data
function _M.push_fd(rid, fd, name, data)
  local node = attach_info.get(rid)
  if node then
    cluster.send(node, '@.transit', 'client_push', rid, fd, name, data)
  else
    local msg = sender(name, data):pack('>s2')
    socketdriver.send(fd, msg)
    print_m(name, 'send >>>')
  end
end

-- Push one message to fds.
-- @param table fds [fd] = rid
-- @param string name
-- @param table data
function _M.push_fds(fds, name, data)
  local msg = sender(name, data):pack('>s2')
  print_m(name, 'send >>>')
  for fd, rid in pairs(fds) do
    local node = attach_info.get(rid)
    if node then
      cluster.send(node, '@.transit', 'client_push', rid, fd, name, data)
    else
      socketdriver.send(fd, msg)
    end
  end
end

-- Push one message to player objs.
-- @param table The object table.
-- @param string name
-- @param table data
function _M.push_objs(objs, name, data)
  local msg = sender(name, data):pack('>s2')
  print_m(name, 'send >>>')
  for _, obj in pairs(objs) do
    if obj.is_player then
      local node = attach_info.get(obj.rid)
      if node then
        cluster.send(
          node, '@.transit', 'client_push', obj.rid, obj.fd, name, data)
      else
        socketdriver.send(obj.fd, msg)
      end
    end
  end
end

function _M.init(s, c)
  local sprotoloader = require 'sprotoloader'
  local proto_loader = skynet.uniqueservice 'proto_loader'
  local slot_s = skynet.call(proto_loader, 'lua', 'index', s)
  host = sprotoloader.load(slot_s):host 'package'
  local slot_c = skynet.call(proto_loader, 'lua', 'index', c)
  sender = host:attach(sprotoloader.load(slot_c))
end

return _M
