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
local e_role_status = require 'enum.role_status'

-- Data.
-------------------------------------------------------------------------------

local traceback = trace.traceback
local _CH = client.handler()

local _M = {}
local _S = {}

local c_online_max <const> = 3000

local cache = login.cache
local sockets = login.sockets

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
      -- local _ = login.agent_pool and login.agent_pool:gc()
    end
    login.clear_timeout()
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
      local agent = agent_pool.get(rid)
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
  login.agent_pool = service_pool.new({ cap = 100, boot = 'world/agent' })
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

-- Get role agent.
function _M.get_role_agent(rid, force)
  return login.get_agent(rid, force)
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
