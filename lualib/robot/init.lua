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

-- Local defines.
local math = math
local xpcall = xpcall

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

end

-- Enter game.
function enter_game(self)

end

-- Auth account and enter game(not role then create).
function auth_game(self)

end

-- Auth game and enter(connect game server).
function login_game(self)

end
