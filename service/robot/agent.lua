--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id agent.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/11 19:51
 - @uses The robot agent.
--]]

local skynet = require 'skynet'
local robot = require 'robot'
local client = require 'robot.client'
local log = require 'log'
local setting = require 'setting'
local util = require 'util'
local obj -- The robot object.

-- Data.
-------------------------------------------------------------------------------

local _M = {}

-- Local functions.
-------------------------------------------------------------------------------

-- Loop.
local function loop()
  skynet.sleep(20)
  local r = obj:login_account()
  print('login_account:', r)
  if r then
    if obj:login_game() then
      if not obj.roles or not next(obj.roles) then
        r = obj:create_role()
      end
      if r then
        obj:enter_game()
      end
    end
  end
end

-- API.
-------------------------------------------------------------------------------

-- Init.
-- @param number id
function _M.init(id)
  local uid_prefix = setting.get('uid_prefix')
  local uid = tonumber(tostring(uid_prefix) .. tostring(id))
  local myrobot <close> = setmetatable(robot, {
    __close = function(t, err)
      t:release()
    end
  })
  obj = myrobot
  print('the obj========================', obj)
  obj:init({ uid = uid, pid = id })
end

return {
  command = _M,
  require = {},
  init = function()
    math.random(util.time())
    client.init('s2c', 'c2s')
    skynet.fork(loop)
  end
}
