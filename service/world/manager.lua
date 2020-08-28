--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id manager.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/18 20:17
 - @uses The world manager service.
         Accept new connection and clients.
--]]

local skynet = require 'skynet'
local client = require 'client'
local queue = require 'skynet.queue'
local cluster = require 'skynet.cluster'
local login = require 'world.login'
local auth_tool = require 'login.auth_tool'
local util = require 'util'
local trace = require 'trace.c'
local service_pool = require 'service_pool'
local log = require 'log'
local setting = require 'setting'
local server = require 'server'
local e_error = require 'enum.error'

-- Data.
-------------------------------------------------------------------------------

local traceback = trace.traceback
local _CH = client.handler()

local _M = {}
local _S = {}

local c_online_max <const> = 3000

local agent_pool = agent_pool or nil
local sockets = sockets or {}
local cache = cache or { 
  online = 0
}
local onlines = onlines or {}

-- Local functions.
-------------------------------------------------------------------------------

-- Garbage collect.
local function gc()
  local last_t = util.time()
  local now
  repeat
    now = util.time()
    if now - last_t >= 300 then
      last_t = now
      local list = skynet.call('.launcher', 'lua', 'LIST')
      for addr in pairs(list) do
        xpcall(skynet.call, traceback, addr, 'debug', "GC")
        skynet.error('gc called')
      end
      -- local _ = agent_pool and agent_pool:gc()
    end
    skynet.sleep(100)
  until false
end

-- Main loop.
local function loop()

end

local function init()
  client.init('c2s', 's2c')

  skynet.fork(loop)

  skynet.fork(gc)
end

-- Socket message.
-------------------------------------------------------------------------------

function _S.data(gate, fd, msg)
  local socket = sockets[fd]
  if socket.authed then
    client.dispatch(socket, msg)
  elseif nil == socket.authed then
    socket.authed = false
    local ok, err = pcall(client.dispatch_special, socket, 'auth_game', msg)
    if ok and socket.authed then
      return
    elseif not ok then
      log:warn('auth game error: %s', err)
    end
  else
    log:info('need auth game')
    skynet.call(socket.gate, 'lua', 'kick', fd)
  end
end

function _S.open(gate, fd, addr)
  sockets[fd] = {
    gate = gate,
    addr = addr,
    fd = fd
  }
  cache.connection_count = (cache.connection_count or 0) + 1
  skynet.call(gate, 'lua', 'accept', fd)
  log:info('socket open %d', fd)
end

function _S.close(gate, fd)
  log:info('socket close %d', fd)
  local socket = sockets[fd]
  if socket then
    sockets[fd] = nil
    cache.connection_count = cache.connection_count - 1
    local rid = socket.rid
    if rid then
      local agent = onlines[rid]
      if agent then
        if not xpcall(skynet.call, traceback, agent, 'lua', 'afk', rid) then
          log:warn('call agent afk failed, rid %s', rid)
        end
      end
    end
  end
end

function _S.error(gate, fd, msg)
  log:info('socket error %d', fd)
  _S.close(gate, fd)
end

function _S.warning(gate, fd, sz)
  log:info('socket warning %d', fd)
  local socket = sockets[fd]
  if socket then
    skynet.send(
      gate, 'lua', 'kick', fd, string.format('write buffer too big %dK', sz))
  end
end

-- API.
-------------------------------------------------------------------------------

-- Service init on open.
function _M.init()
  agent_pool = service_pool.new({ cap = 100, boot = 'world/agent' })
end

-- Open gate.
function _M.open(args)

  _M.init()

  local gate = skynet.newservice('world/gate')
  args.watchdog = skynet.self()
  skynet.call(gate, 'lua', 'open', args)
  skynet.call('.launcher', 'lua', 'GC')
  
  log:debug('version: %s', setting.get('version'))
  return true
end

-- Client handler.
-------------------------------------------------------------------------------

function _CH:auth_game(msg)
  log:dump(msg, 'auth_game======================')
  
  if cache.online >= c_online_max then
    self.kick = true
    return { e = e_error.server_full, m = 'Server full' }
  end

  if not msg.version then
    self.kick = true
    log:warn('Unknown version uid[%s]', msg.uid)
    return { e = e_error.version_invalid, m = 'Invalid version' }
  end
  local c_version = tonumber(msg.version)
  local s_version = tonumber(setting.get('version'))
  if c_version < s_version then
    self.kick = true
    log:warn('Invalid version uid[%s], client version[%s], server version[%s]',
      msg.uid, c_version, s_version)
    return
  end

  -- Other check add here.

  local r = false
  if self.auth_info then
    r = auth_tool.check(self.auth_info, msg.token, msg.time)
  end
  if not r then
    local c_name = 'login_' .. msg.auth
    -- print('c_name===============', c_name)
    local auth_info, err = cluster.call(c_name, '@auth_mgr', 'check_token', 
      msg.uid, msg.token, msg.time)
    print('auth_info, err', auth_info, err)
    if auth_info then
      self.auth_info = auth_info
      log:info('Check token success, fd[%d] uid[%s](%s)', 
        self.fd, msg.uid, msg.token)
    else
      log:info('Check token failure, fd[%d] uid[%s](%s) error[%s]',
        self.fd, self.uid, msg.uid, msg.token, err)
        return { e = e_error.auth_failed, m = 'auth failed' }
    end
  end

  -- Passed an set.
  self.uid = msg.uid
  self.auth = msg.auth
  self.sid = msg.sid

  if not self.roles then

  end

  return {e = e_error.none}
end

return {
  init = init,
  command = _M,
  dispatch = {
    lua = function(session, source, cmd, scmd, ...)
      if 'socket' == cmd then
        local f = _S[scmd]
        f(source, ...)
      else
        local f = _M[cmd]
        if f then
          if session > 0 then
            skynet.retpack(f(scmd, ...))
          else
            f(scmd, ...)
          end
        else
          log:warn('unknown command[%s]', cmd)
          if session > 0 then
            skynet.response()(false)
          end
        end
      end
    end
  }
}
