--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id role_mgr.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/21 19:55
 - @uses Role manager.
--]]

local skynet = require 'skynet'
local client = require 'client'
local role = require 'world.role'
local role_db = require 'world.role.db'
local scene = require 'world.role.scene'
local server = require 'server'
local log = require 'log'
local queue = require 'skynet.queue'
local trace = require 'trace.c'
local util = require 'util'
local mod = require 'world.role.mod'
local e_error = require 'enum.error'

-- Data.
-------------------------------------------------------------------------------

local table = table
local coroutine = coroutine
local xpcall = xpcall
local traceback = trace.traceback
local print = print
local ipairs = ipairs
local pairs = pairs

local _RH = role.handler

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

hash = hash or {}               -- Role rid hash [rid] = role.
fds = fds or {}                 -- Role fd hash [fd] = role.
locks = locks or {}             -- Role lock queue function hash.
waitings = waitings or {}       -- Enter waiting list(wait role enter).

-- Local functions.
-------------------------------------------------------------------------------

-- Check a waiting before enter game.
-- @param string rid Role id.
local function waiting_check(rid)
  if not waitings[rid] then
    waitings[rid] = {
      cos = {},                 -- Coroutine list.
      time = util.time(),       -- Start time.
    }
  end
end

-- Enter waiting.
-- @param string rid Role id.
local function waiting_enter(rid)
  local info = waitings[rid]
  if not info then return end
  local co = coroutine.running()
  table.insert(info.cos, co)
  log:info('waiting enter begin rid[%s] coroutine[%s]', rid, tostring(co))
  skynet.wait(co)
  log:info('waiting enter end rid[%s] coroutine[%s]', rid, tostring(co))
end

-- Clear a waiting of role.
-- @param string rid Role id.
local function waiting_clear(rid)
  local info = waitings[rid]
  if info then
    for _, co in ipairs(info.cos) do
      skynet.wakeup(co)
    end
    waitings[rid] = nil
  end
end

-- Check waiting time out.
local function check_waiting_timeout()
  local now = util.time()
  local clears = {}
  for rid, info in pairs(waitings) do
    if now - info.time > 5 then
      table.insert(clears, rid)
    end
  end
  for _, rid in ipairs(clears) do
    log:warn('check_waiting_timeout clear[%s]', rid)
    waiting_clear(rid)
  end
end

-- On role enter.
-- @param table self The role object.
local function on_enter(self)
  local rid = self.id
  log:info('%s on_enter db_loaded: %s', rid, self.db_loaded)
  if not self.db_loaded then
    self.db_proxy = server:db_proxy()
    print('mod========================load')
    mod.load(self)
    add(self)
    self.db_loaded = true
  else
    fds[self.fd] = self
  end

  local r, err = xpcall(function()
    
    -- Models enter handle.
    mod.enter(self)
  
    scene.enter_map(self)

    mod.after_enter(self)

    role_db.update_player(self, 1)

  end, traceback)

  if not r then
    mod.unload(self)
    del(self.id)
    log:warn('on_enter error rid[%s] err[%s]', rid, err)
    return false
  end

  log:info('on_enter success rid[%s]', rid)
  return true
end

-- Role on afk.
local function on_afk(self)

end

-- Role on leave.
local function on_leave(self)

end

-- Lua message handler from agent.
-------------------------------------------------------------------------------

-- Enter game.
function _RH:enter()
  print('role enter=======================================', self)
  local rid = self.id
  if not rid then
    log:warn('Role enter cannot find the rid')
    return false
  end
  print('role enter=======================================', 1)
  local obj = hash[rid]
  if not obj then
    obj = role.new(self)
  end
  local fd = self.fd
  if fd then
    obj.fd = fd
  end
  print('role enter=======================================', 2)
  if obj.gate then -- Client login.
    waiting_check(rid)
    if not skynet.call(obj.gate, 'lua', 'forward', obj.fd) then
      waiting_clear(rid)
      return false
    end
  end
  local lock = get_lock(rid)
  local r = lock(on_enter, obj)

  waiting_clear(rid)

  return r
end

-- Afk.
function _RH:afk()

end

-- API.
-------------------------------------------------------------------------------

function init()

end

function check_timeout()
  check_waiting_timeout()
end

function on_client_msg(fd, msg, sz)
  local obj = get_by_fd(fd)
  if obj then
    local lock = get_rid_lock(obj.id)
    client.dispatch(obj, msg, sz, lock)
  end
end

function add(r)
  fds[r.fd] = r
  hash[r.id] = r
end

-- Get role.
-- @param string rid Role ID.
-- @return mixed
function get(rid)
  return hash[rid]
end

-- Delete role.
-- @param string rid
function del(rid)
  local r = hash[rid]
  fds[r.fd] = nil
  hash[rid] = nil
end

-- Get by fd.
-- @param number fd
-- @return mixed
function get_by_fd(fd)
  return fds[fd]
end

-- Delete by fd.
-- @param number fd
function del_by_fd(fd)
  local role = fds[fd]
  if role then
    fds[fd] = nil
    hash[role.id] = nil
  end
end

function get_lock(rid)
  if not locks[rid] then
    locks[rid] = queue()
  end
  return locks[rid]
end

function del_lock(rid)
  locks[rid] = nil
end

function process(cmd, ...)
  local f = _RH[cmd]
  if not f then
    log:warn('process unknown command[%s]', cmd)
    return
  end
  for _, role in pairs(hash) do
    f(role, ...)
  end
end

function on_lua_msg(session, cmd, rid, ...)
  local f = _RH[cmd]
  print('on_lua_msg', cmd, rid, ...)
  if f then
    if rid then
      print('on_lua_msg', cmd, rid)
      waiting_enter(rid)
      if 'enter' == cmd then
        if session > 0 then
          skynet.retpack(f(rid, ...))
        else
          f(rid, ...)
        end
      else
        local obj = get(rid)
        if obj then
          if 'check' == cmd then
            skynet.retpack(true)
          end
          if session > 0 then
            skynet.retpack(f(obj, ...))
          else
            f(obj, ...)
          end
        else
          if 'check' == cmd then
            skynet.retpack(false)
          else
            log:warn('on_lua_msg rid[%s] invalid cmd[%s]', rid, cmd)
            local _ = session > 0 and skynet.retpack(false)
          end
        end
      end
    else
      if session > 0 then
        skynet.retpack(f(...))
      else
        f(...)
      end
    end
  else
    f = _M[cmd]
    if f then
      assert(0 == session)
      f(...)
    else
      log:warn('on_lua_msg unknown command[%s]', cmd)
      if session > 0 then
        skynet.retpack(false)
      end
    end
  end
end
