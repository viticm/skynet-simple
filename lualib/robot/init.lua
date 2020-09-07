--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id init.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/10 20:26
 - @uses The robot class.
--]]

local skynet = require 'skynet'
local socket = require 'skynet.socket'
local setting = require 'setting'
local client = require 'robot.client'
local md5 = require 'md5'
local trace = require 'trace.c'
local log = require 'log'
local action = require 'robot.action'
require 'robot.action.load' -- Load all actions.

-- Local defines.
local math = math
local xpcall = xpcall
local pcall = pcall
local print = print
local next = next

-- Data.
-------------------------------------------------------------------------------

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

-- API.
-------------------------------------------------------------------------------

-- Init.
-- @param table data The robot data.
function init(self, data)
  self.run_mod = setting.get('run_mod')
  self.pid = data.pid
  self.account = {uid = data.uid}
end

-- Release
function release(self)
  if self.fd then socket.close(self.fd) end
end

-- Send message.
-- @param string name Package name.
-- @param table data Package data.
function send(self, name, data)
  client.push(self, name, data)
end

-- Is connected.
-- @return bool
function is_connected(self)
  return self.fd and not socket.invalid(self.fd) or false
end

-- Ping server.
function ping(self)
  
end

-- Request from server.
-- @param string name Package name.
-- @param table data Package data.
function request(self, name, data)
  return client.request(self, 300, name, data)
end

-- Signup account.
-- @return bool
function signup(self)
  if not self:is_connected() then return false end
  local account_prefix = setting.get('account_prefix')
  local uid = self.account.uid
  local msg = {
    channel = 100,
    devive = 1,
    imei = math.random(100000, 999999),
    user_name = account_prefix .. uid,
    password = md5.sumhexa(account_prefix .. uid),
    mobile = '',
    email = ''
  }
  local r = self:request('signup', msg)
  if 0 == r.e then
    log:info('signup uid[%d] success', uid)
  else
    log:warn('signup uid[%d] failed, error[%s]', uid, r.e)
  end
  return 0 == r.e
end


-- Signin account.
-- @return bool
function signin(self)
  if not self:is_connected() then return false end
  local uid = self.account.uid
  local msg = {
    channel = 100,
    imei = uid,
    devive = 'MyTestDevive',
    user_name = uid,
    password = uid,
    model = '',
    partenerid = 100,
    gameid = 0
  }
  local r = self:request('signin', msg)
  if 0 == r.e then
    log:info('signin uid[%d] success', uid)
    self.account.uid = r.uid
    self.account.auth = r.auth
    self.account.token = r.token
    print('self.account.auth', self.account.auth)
  else
    log:warn('signin uid[%d] failed[%d]', uid, r.e)
  end
  return 0 == r.e
end

-- Auto signup and signin(connect login server).
function login_account(self)

  skynet.sleep(100)

  local cfg = setting.get('login')
  local host = cfg.ip
  local port = cfg.port
  local account = self.account
  local uid = account.uid
  local fd = socket.open(host, port)
  log:debug('login account: %s %d', host, port)
  if not fd then
    return self:login_account() -- loop
  end
  log:info('login_account open fd[%d]', fd)

  self.fd = fd

  -- Dispatch.
  skynet.fork(function() 
    local ok, err = xpcall(client.dispatch, trace.traceback, self)
    if not ok then
      log:warn(err)
    end
  end)

  -- Try signin.
  local r = self:signin()
  if not r then
    if not self:signup() then
      socket.close(fd)
      return self:login_account()
    end
    -- Try signin again.
    if not self:signin() then
      socket.close(fd)
      return self:login_account()
    end
  end

  socket.close(fd)

  self.logined = true

  return true
end

-- Create role to world.
function create_role(self)
  local account = self.account
  local index = #(self.roles or {}) + 1
  local name = 'robot_' .. account.uid .. '_' .. index
  local job = math.random(1, 3)
  local sex = math.random(0, 1)
  local msg = {name = name, job = job, sex = sex}
  local r = client.request(self, 500, 'create_role', msg)
  if 0 == r.e then
    log:info('%d create role[%s] success', account.uid, name)
    return true
  else
    log:warn('%d create role[%s] failed, err: %d', account.uid, name, r.e)
    return false
  end
end

-- Enter game.
function enter_game(self)
  local account = self.account
  if not self.roles or not next(self.roles) then
    log:warn('%d enter game have no role', account.uid)
    return false
  end
  local role = self.roles[1]
  local r = client.request(self, 1000, 'enter', {rid = role.id})
  local name = role.name
   if 0 == r.e then
    log:info('%d enter game role[%s] success', account.uid, name)
    return true
  else
    log:warn('%d enter game role[%s] failed, err: %d', account.uid, name, r.e)
    return false
  end
end

-- Auth account and enter game(not role then create).
function auth_game(self)
  local account = self.account
  local time = math.random(1000000000, 9999999999)
  local msg = {
    uid = account.uid,
    auth = account.auth,
    time = time,
    token = md5.sumhexa(account.token .. time),
    sid = self.sid,
    version = '20200826'
  }
  local r = client.request(self, 500, 'auth_game', msg)
  if 0 == r.e then
    log:info('auth game success[%s]', account.uid)
  else
    log:warn('auth game failed[%s], err[%d]', account.uid, r.e)
    return false
  end

  skynet.sleep(100)

  local roles = self.roles

  print('auth game roles', roles)

  return true
end

-- Auth game and enter(connect game server).
-- @return bool
function login_game(self)
  skynet.sleep(100)
  local pid = self.pid
  local sid = self.sid
  local cfg = setting.get('world')
  local game_host = cfg.ip
  local game_port = cfg.port
  local fd = socket.open(game_host, game_port)
  if not fd then return false end
  log:info('login game open fd: %d', fd)
  self.fd = fd
  skynet.fork(function() 
    local ok, err = pcall(client.dispatch, self)
    if not ok then
      log:warn('login game dispatch error %d', err or -1)
    end
  end)
  local r = self:auth_game()
  if not r then
    return self:login_game()
  end
  return r
end

-- Doing action with config.
function do_action(self)

end
