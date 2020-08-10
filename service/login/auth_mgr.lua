--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id auth_mgr.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/03 14:17
 - @uses The auth manager for login.
--]]

local skynet = require 'skynet'
local auth_tool = require 'login.auth_tool'
local service_provider = require 'service_provider'
local util = require 'util'
local log = require 'log'

-- Data.
-------------------------------------------------------------------------------

local auths = auths or {}
local gates = gates or {}
local tokens = tokens or {}
local onlines = onlines or {}
local authed_count = authed_count or 0
local _M = {}

-- Local functions.
-------------------------------------------------------------------------------

local function clear_timeout()
  local now = skynet.now()
  local clears = {}
  for k, v in pairs(tokens) do
    if v.item + 30000 < now then -- 5min clear
      table.insert(clears, k)
    end
  end
  local _ = next(clears) and log:dump(clears, 'clear_timeout')
  for _, key in ipairs(clears) do
    tokens[key] = nil
  end
end

-- API.
-------------------------------------------------------------------------------

function _M.start_auth(count)
  for i = 1, count do
    table.insert(auths, skynet.newservice('login/auth', skynet.self()))
  end
end

function _M.stop_auth()
  for _, auth in ipairs(auths) do
    skynet.call(auth, 'lua', 'stop')
  end
  auths = {}
end

function _M.start_gate(ip, port)
  assert(#auths > 0, 'need start auth first')
  local gate = skynet.newservice('login/gate')
  skynet.call(gate, 'lua', 'open', ip, port, auths)
  table.insert(gates, gate)
  return true
end

function _M.stop_gate()
  for _, gate in ipairs(gates) do
    skynet.call(gate, 'lua', 'stop')
  end
  gates = {}
end

-- Add one token.
-- @param table token The token info table.
function _M.add_token(token)
  local uid = assert(tostring(token.uid))
  log:info('add_token: uid = %s, token = %s', uid, assert(token.token))
  token.time = skynet.now()
  tokens[uid] = token
  onlines[uid] = nil
  authed_count = authed_count + 1
end

-- Check an user token.
-- @param mixed uid
-- @param ...
-- @return bool, string
function _M.check_token(uid, ...)
  uid = tostring(uid)
  local token = tokens[uid]
  if not token then
    token = onlines[uid]
    if not token then
      log:warn('check_token timeout uid = %s', uid)
      return false, 'timeout'
    end
  end
  local r = auth_tool.check(token, ...)
  if not r then
      log:warn('check_token failed uid = %s', uid)
      return false, 'failed'
  end
  log:info('check_token succeed uid = %s', uid)
  return token
end

-- Update the token.
-- @param number flag 1 is login else logout.
function _M.update_token(flag, uid)
  if 1 == flag then
    local token = tokens[uid]
    if token then
      onlines[uid] = token
      tokens[uid] = nil
      log:info('update token login: uid = %s, token = %s', uid, token.token)
    end
  else
    local token = onlines[uid]
    if token then
      tokens[uid] = token
      onlines[uid] = nil
      log:info('update token logout: uid = %s, token = %s', uid, token.token)
    end
  end
end

-- Update player to db.
-- @param number number flag The 1 is login else logout.
-- @param table info The player info.
function _M.update_player(flag, info)
  _M.update_token(flag, info.uid)
  if 1 == flag then
    info.time = util.time()
  end
  local index = math.random(1, #auths)
  skynet.call(auths[index], 'lua', 'update_player', info)
end

-- Kick one user.
-- @param string uid The user id.
function _M.kick(uid)
  tokens[uid] = nil
  onlines[uid] = nil
end

-- Get auth info.
-- @return number, number, number
function _M.auth_info()
  local pcl_time, pcl_count = 0, 0
  for _, auth in ipairs(auths) do
    local time, count = skynet.call(auth, 'lua', 'auth_info')
    pcl_time = pcl_time + time
    pcl_count = pcl_count + count
  end
  return pcl_time, pcl_count, authed_count
end

-- Get user role list by id.
-- @param string uid
-- @return bool, mixed
function _M.get_roles(uid)
  local index = math.random(1, #auths)
  local r, data = skynet.call(auths[index], 'lua', 'get_roles', uid)
  if not r then
    return false, data
  end
  local roles = {}
  for _, v in pairs(data) do
    local sid = v[3]
    roles[sid] = {
      rid = v[1],
      rname = v[2],
      sid = sid,
      level = v[4]
    }
  end
  return true, 0, roles
end

return {
  quit = true,
  command = _M,
  info = {auths, tokens},
  init = function()
    skynet.fork(function() 
      while true do
        clear_timeout()
        skynet.sleep(100)
      end
    end)
  end,
  release = function()
    _M.stop_auth()
    _M.stop_gate()
  end
}
