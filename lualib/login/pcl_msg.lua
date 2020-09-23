--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id pcl_msg.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/04 19:33
 - @uses The pcl message class.
--]]

local skynet = require 'skynet'
local util = require 'util'
local setting = require 'setting'
local pcl = require 'pcl'
local login_db = require 'login.db'
local log = require 'log'
local e_error = require 'enum.error'

local format = string.format
local urandom = assert(io.open('/dev/urandom', 'r'))

-- Data.
-------------------------------------------------------------------------------

local sid = skynet.getenv('svr_id')
local auth_mgr
local _info = {use_time = 0, use_count = 0}
local c_success <const> = 20000

local _M = {}

-- Local functions.
-------------------------------------------------------------------------------

-- Generate a token.
-- @return string
local function gen_token()
  local str = urandom:read(64)
  local r = string.gsub(str, '([^a-aA-Z0-9])', function(c)
    return format('%02x', string.byte(c))
  end)
  return string.sub(r, 1, 64)
end

-- Record pcl info.
-- @param number time The request begin time.
local function record(time)
  _info.use_time = _info.use_time + skynet.now() - time
  _info.use_count = _info.use_count + 1
end

-- On login.
-- @param table self Socket table.
-- @param table msg Login msg.
-- @param table r The platform login result.
local function on_login(self, msg, r)
  self.exit = true
  if r.code ~= c_success then
    return {e = r.code, m = r.err}
  end
  local info = r.data.user_info
  local user_status = info.status
  local uid = info.id
  local is_white = info.special
  local channel = info.channel
  local platform = info.channel
  local model = info.model
  local last_t = util.time()
  local r = login_db('select last from t_user where uid = "%s"', uid)
  log:dump(r, 'login_db========================')
  if r[1] then
    login_db(
      format('update t_user set last = %d where uid = "%s"', last_t, uid))
    last_t = r[1].last
  else
    login_db(
      format('replace into t_user(uid, last) values ("%s", %d)', uid, last_t))
  end
  r = login_db(format(
    'select level, rname, icon, sid, last from t_player where uid = "%s"', uid))
  local token = gen_token()
  local save_token = {
    last = last_t,
    token = token,
    uid = uid,
    auth = skynet.self(),
    is_white = is_white,
    channel = channel,
    platform = platform,
    model = model,
    imei = msg.imei or '',
    devive = msg.device,
    partner_id = msg.partner_id
  }
  skynet.call(auth_mgr, 'lua', 'add_token', save_token)
  log:info('on_login uid: %s', uid)
  local roles = {}
  for _, v in ipairs(r) do
    local one = {
      level = v[1],
      rname = v[2],
      icon = v[3],
      sid = v[4],
      last = v[5]
    }
    table.insert(roles, one)
  end
  return {
    e = e_error.none,
    uid = uid,
    token = save_token.token,
    roles = roles,
    sid = sid,
    is_white = is_white,
    server_time = util.time(),
    time_zone = util.time_zone(),
    auth = sid
  }
end

-- API.
-------------------------------------------------------------------------------

-- Reg user from platform.
-- @param table self
-- @param table msg
-- @return table
function _M.reg_user(self, msg)
  self.exit = true
  local start_t = skynet.now()
  local r = pcl.post('user/create', msg)
  record(start_t)
  return {e = r.code, m = r.err}
end

-- Login user.
-- @param table self
-- @param table msg
-- @return table
function _M.login(self, msg)
  local start_t = skynet.now()
  local r = pcl.post('user/login', msg)
  record(start_t)
  return on_login(self, msg, r)
end

-- Special login.
-- @param table self
-- @param mixed uid
-- @return table
function _M.special_login(self, uid)
  local msg = {
    imei = uid,
    devive = uid,
  }
  local data = {
    code = 0,
    user_info = {
      id = uid,
      status = 1,
      special = 1,
      channel = 100,
      game_id = 1
    }
  }
  return on_login(self, msg, data)
end

-- Auto login(include create)
-- @param table self
-- @param table msg
-- @return table
function _M.auto_login(self, msg)
  local start_t = skynet.now()
  local r = pcl.post('user/create', msg)
  record(start_t)
  return on_login(self, msg, r)
end

skynet.init(function() 
  local timeout = setting.get('auth_timeout') or 300
  pcl.init(setting.get('pcl'), timeout)

  auth_mgr = skynet.uniqueservice 'login/auth_mgr'
end)

return _M
