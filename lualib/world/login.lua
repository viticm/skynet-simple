--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id login.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/18 20:22
 - @uses The world login module(auth create and login).
         cn: 玩家登陆模块，主要负责玩家进入游戏前的逻辑处理
             一个账号只支持一个角色在线，因为在重登时会下线当前登陆的角色，但
             不会从agent缓存中删除
--]]

local skynet = require 'skynet'
local client = require 'client'
local server = require 'server'
local role_db = require 'world.role.db'
local util = require 'util'
local queue = require 'skynet.queue'
local trace = require 'trace.c'
local e_error = require 'enum.error'

-- Data.
-------------------------------------------------------------------------------

local _CH = client.handler()

local traceback = trace.traceback

local name_size_max <const> = 10          -- The role name length max.
local wait_kick_online <const> = true     -- Login wait kick when role online.
local wait_kick_time <const> = 30         -- Login wait kick time(second).

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

enterings = enterings or {}                 -- Entering list.
afks = afks or {}                           -- Afk list.
cache = cache or { 
  online = 0
}
uid_locks = uid_locks or {}                 -- UID lock functions.
uid_timeout_locks = uid_timeout_locks or {} -- UID check lock timeout uid list.
rid_locks = rid_locks or {}                 -- Role id lock functions.
rid_timeout_locks = rid_timeout_locks or {} -- Role id check lock timeout uid list.
agent_pool = agent_pool or nil
sockets = sockets or {}                     -- Sokect fd hash.
onlines = onlines or {}                     -- User onlie hash[uid] = rid.
                                            -- Current online, not system.
-- Local functions.
-------------------------------------------------------------------------------

-- Add uid lock timeout check to list.
-- @param number uid
local function add_timeout_uid_lock(uid)
  uid_timeout_locks[uid] = util.time()
end

-- Get uid lock function.
-- @param number uid
-- @return function
local function get_uid_lock(uid)
  if not uid_locks[uid] then
    uid_locks[uid] = queue()
  end
  add_timeout_uid_lock(uid)
end

-- Add rid lock timeout check to list.
-- @param number rid Role id.
local function add_timeout_rid_lock(rid)
  rid_timeout_locks[rid] = util.time()
end

-- Get uid lock function.
-- @param number uid
-- @return function
local function get_rid_lock(rid)
  if not rid_locks[rid] then
    rid_locks[uid] = queue()
  end
  add_timeout_rid_lock(rid)
end

-- Clear timeout locks.
-- @param number now The current timestamp.
local function clear_timeout_locks(now)
  for k, v in pairs(uid_timeout_locks) do
    if now - v > 60 then -- One minute
      uid_locks[k] = nil
      uid_timeout_locks[k] = nil
    end
  end
  for k, v in pairs(rid_timeout_locks) do
    if now - v > 60 then -- One minute
      rid_locks[k] = nil
      rid_timeout_locks[k] = nil
    end
  end
end

-- Check repeat enter.
-- @param number uid User id.
-- @return mixed
local function check_repeat_enter(uid)
  local rid = onlines[uid]
  if not rid then return end
  local agent = agent_pool.get(rid)
  if agent then
    skynet.send(agent, 'lua', 'kick', rid)
  end
  local start_t = util.time()
  if wait_kick_online then
    repeat
      skynet.sleep(1)
    until not onlines[uid] or util.time() - start_t > wait_kick_time
  end
end

-- Enter to game world(to map).
-- @param table self The socket table.
-- @param table role The role object.
-- @return mixed
local function enter(self, role)
  local rid = role.id
  local uid = role.uid
  local agent
  local lock = get_rid_lock(rid)
  lock(function()
    check_repeat_enter(uid)

    if self.login_time ~= enterings[rid] then
      return
    end
    
    agent = agent_pool:get(rid)
    if not agent then
      return
    end

    local fd = self.fd
    local role = {}
    role.gate = self.gate
    role.addr = self.addr
    role.fd = fd
    role.uid = uid
    role.sid = self.sid
    role.sname = server.name
    role.node = server.node
    role.auth = self.auth
    sockets[fd].rid = rid

    cache.online = cache.online + 1

    log:info('world enter [agent:%08x] for '..
    'fd[%d](rid: %d, rname: %s, sid: %d, sname: %s) online: %d', 
      agent, rid, role.rname, role.sid, role.sname, cache.online)

    local r, err = 
      xpcall(skynet.call, traceback, agent, 'lua', 'enter', rid, role)
    if not r or not err then
      log:warn('try call agent enter failed, rid[%s], err: %s', rid, err)
      sockets[fd].rid = nil
      cache.online = cache.online - 1
      agent = nil
      agent_pool:free(rid)
    end
  end)
  return agent
end

-- API.
-------------------------------------------------------------------------------

-- Clear logining timeout.
function clear_timeout()
  local now = util.time()
  clear_timeout_locks(now)
end

-- Clear user online.
-- @param number uid
function clear_user_online(uid)
  onlines[uid] = nil
end

-- Get role agent.
-- @param string rid Role ID.
-- @param mixed force If not find need auto enter game.
-- @return mixed
function get_agent(rid, force)
  local agent = agent_pool:get(rid, true)
  if not agent then -- Auto login game.
    agent = agent_pool:get(rid)
    local role = { rid = rid }
    local r, err = 
      xpcall(skynet.call, traceback, agent, 'lua', 'enter', role)
    if not r or not err then
      log:warn('try call agent enter failed, rid[%s], err: %s', rid, err)
      agent = nil
      agent_pool:free(rid)
    end
  end
  return agent
end

-- Message.
-------------------------------------------------------------------------------

-- Ping.
function _CH:ping(msg)
  return {time = util.time()}
end

-- Auth game.
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

  print('====================================auth')
  if not self.roles then
    self.db_proxy = server:db_query()
    print('self.db_proxy', self.db_proxy)
    self.roles = role_db.fetch_roles(self.db_proxy, tonumber(self.uid))
  end
  print('================================auth game')

  -- Send roles.
  local msg = {
    list = self.roles
  }
  client.push(self, 'roles', msg)
  log:dump(self.roles, 'current roles: ' .. self.uid)

  self.status = e_role_status.auth

  return {e = e_error.none}
end

-- Create role
function _CH:create_role(msg)
  local now = util.time()

  if self.status ~= e_role_status.auth then
    log:warn('%s create role not in auth status', self.uid)
    return { e = e_error.invalid_operation, m = 'not in auth' }
  end

  if util.strlen(msg.name) > name_size_max then
    log:warn('%s create role name[%s] size[%d] error', 
      self.uid, msg.name, util.strlen(msg.name))
    return { e = e_error.name_size, m = 'name size error' }
  end

  -- Fliter.

  msg.uid = self.uid
  msg.sid = self.sid
  msg.platform = self.auth_info.platform or ''
  local r = role_db.create_role(self.db_proxy, msg)
  if r ~= e_error.none then
    log:warn('%s create role name[%s] failed! error[%d]')
    return { e = r, m = 'create failed: ' .. r }
  end

  self.create_time = now
  self.roles = role_db.fetch_roles(self.db_proxy, self)
  self.status = role_status.create

  -- Auto enter.
  _CH.enter(self, msg)

  return {
    e = e_error.none,
    rid = msg.rid,
    create_time = msg.create_time
  }

end

-- Enter game.
function _CH:enter(msg)
  
  local now = util.time()

  if self.status ~= e_role_status.auth and 
    self.status ~= e_role_status.create then
    log:warn('%s enter failed, status[%d] invalid', self.uid, self.status)
    return { e = e_error.invalid_operation, m = 'invalid operation' }
  end
  local rid = msg.rid
  local role = {}
  for _, info in ipairs(self.roles) do
    if info.rid == rid then
      role.uid = v.uid
      role.id = v.id
      role.name = v.name
      role.forbid = v.forbid
      role.base = {
        job = v.job
      }
      break
    end
  end
  if not next(role) then
    log:warn('%s enter failed, cannot find the role by rid[%s]', self.uid, rid)
    return { e = e_error.invalid_arg, m = 'invalid role' }
  end

  if self.login_time and now - self.login_time < 5 then
    log:warn('%s enter too fast[%s]', self.uid, rid)
    return { e = e_error.enter_fast, m = 'enter fast' }
  end

  if enterings[rid] then
    log:warn('%s repeat enter rid[%s] time[%d]', self.uid, rid, enterings[rid])
    return { e = e_error.enter_repeat, m = 'enter repeat' }
  end

  self.login_time = now
  enterings[rid] = now

  -- Get agent and try enter scene.
  local lock = get_uid_lock(self.uid)
  local agent = lock(enter, self, role)

end
