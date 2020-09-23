--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id auth.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/04 19:29
 - @uses The auth service.
--]]

local skynet = require 'skynet'
local client = require 'client_socket'
local socket = require 'skynet.socket'
local setting = require 'setting'
local timer = require 'timer'
local pcl_msg = require 'login.pcl_msg'
local login_db = require 'login.db'
local auth_tool = require 'login.auth_tool'
local util = require 'util'
local log = require 'log'
local _CH = client.handler()

-- Data.
-------------------------------------------------------------------------------

local auth_timeout

local _M = {}

-- Local functions.
-------------------------------------------------------------------------------

-- Special login no password.
-- @param table self The socket table.
-- @param string uid
-- @return mixed
local function login_special(self, uid)
  local op = 'login_special'
  return pcl_msg[op](self, uid)
end

-- Local login.
-- @param table self The socket table.
-- @param table msg The login msg.
-- @return mixed
local function login_local(self, msg)
  local op = 'login'
  local json_msg = {
    device = msg.device,
    sdk = {
      username = msg.username,
      password = msg.password,
      time = util.time()
    },
    channel = msg.channel,
    partner = msg.partner,
    ip = util.split_row(self.addr, ':')
  }
  log:dump(json_msg, 'json_msg')
  log:info('login_local partner = %s', msg.partner)
  return pcl_msg[op](self, msg)
end

-- 3rd login.
-- @param table self The socket table.
-- @param table msg The login msg.
-- @return mixed
local function login_3rd(self, msg)
  print('login_3rd')
  local op = 'create_user'
  local json_msg = {
    device = msg.device,
    sdk = {
      username = msg.username,
      password = msg.password,
      time = util.time()
    },
    channel = msg.channel,
    partner = msg.partner,
    ip = util.split_row(self.addr, ':')
  }
  log:info('login_local partner = %s', msg.partner)
  return pcl_msg[op](self, msg)
end

local function loop_error(self, fd, what)
  local close_timer = self.close_timer
  if close_timer then
    self.close_timer = nil
    timer.remove(close_timer)
  end
  if self.fd then
    self.fd = nil
    log:info('loop %s, %s', fd, what or 'unkown')
    socket.close(fd)
  end
end

local function new_warn(self)
  return function(id, sz)
    if id == self.fd then
      loop_error(self, id, string.format('write buffer too big %dK', sz))
    end
  end
end

local function msg_loop(self)
  local fd = self.fd
  self.close_timer = timer.add(100 * (auth_timeout + 2), function()
    self.close_timer = nil
    loop_error(self, fd, 'timeout')
  end)
  client.start(self, new_warn)
  local in_dispatch
  repeat
    local msg, sz = client.read_message(self)
    if not msg then
      loop_error(self, fd, 'closed')
      break
    else
      if in_dispatch then
        loop_error(self, fd, 'disptaching')
      else
        skynet.fork(function()
          if not self.fd then
            loop_error(self, fd, 'closed')
          end
          in_dispatch = true
          client.dispatch(self, msg, sz)
          in_dispatch = nil
          if self.exit then
            loop_error(self, fd, 'exit')
          end
        end)
      end
    end

  until false
end

-- Client handler.
-------------------------------------------------------------------------------

-- Signup.
function _CH:signup(msg)
  if not self.fd then
    return
  end
  local op = 'reg_user'
  local json_msg = {
    devive = msg.device,
    sdkInfo = {
      username = msg.username,
      password = msg.password,
      mobile = msg.mobile or '',
      email = msg.email or '',
      time = util.time()
    },
    channel = msg.channel,
    ip = util.split_row(self.addr, ':')
  }
  return pcl_msg[op](self, json_msg)
end

-- Signin.
function _CH:signin(msg)
  log:dump(msg, 'signin==========================')
  if 100 == msg.channel then
    if msg.imei == msg.username and msg.imei == msg.password then
      log:warn('attention!!! - special login with uid: %s', msg.imei)
      if msg.device ~= auth_tool.login_key then
        log:Info('special login with invalid login key')
        return { e = e_error.unkown, m = 'invalid login' }
      end
      local uid = tonumber(msg.imei)
      if not uid then
        log:warn('special login with invalid uid')
        return { e = e_error.unkown, m = 'invalid login' }
      end
      return login_special(self, uid)
    else
      return login_local(self, msg)
    end
  else
    return login_3rd(self, msg)
  end
end

-- API.
-------------------------------------------------------------------------------

function _M.auth(fd, addr)
  local self = {fd = fd, addr = addr}
  return pcall(msg_loop, self)
end

function _M.update_player(info)
  local sql = util.gen_save_sql('t_player', info, 'uid', { time = 'last' })
  local r = login_db(sql)
  if 0 == r.affected_rows then
    sql = util.gen_save_sql('t_player', info, 'uid', { time = 'last'  }, true)
    login_db(sql)
  end
end

function _M.auth_info()
  return pcl_msg.pcl_cost()
end

function _M.get_roles(uid)
  local sql = string.format(
    'select rid, rname, sid, level from t_player where uid = "%s"', uid)
  local r = login_db(sql)
  if not d or d.errno then
    return false, d.errno
  end
  return true, d
end

return {
  command = _M,
  init = function()
    client.init('c2s', 's2c')
    local auth_setting = setting.get('auth') or {}
    auth_timeout = tonumber(auth_setting.timeout or 10)
  end,
}
