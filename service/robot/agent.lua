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
local action = require 'robot.action'

-- Data.
-------------------------------------------------------------------------------

local _ARH = action.run_handler

local _M = {}

-- Local functions.
-------------------------------------------------------------------------------

-- Loop.
local function loop(obj)
  do
    local _ <close> = obj:ref_guard()
  end
  local run_mod = obj.run_mod
  if not run_mod.no_login then
    local run_args = {}
    repeat
      _ARH.auto_login(obj, nil, run_args)
    until run_args.ended
  end
  obj:do_action()
end

local function exit()
  _M.robot:close()
  -- Wait to collect.
  repeat
    skynet.sleep(1)
  until _M.robot.ref <= 0
  _M.robot = nil
  collectgarbage('collect')
end

-- API.
-------------------------------------------------------------------------------

-- Init.
-- @param number id
function _M.init(id)
  local uid_prefix = setting.get('uid_prefix')
  local uid = tonumber(tostring(uid_prefix) .. tostring(id))
  _M.robot = setmetatable({}, {
    __index = robot,
    __gc = function(t)
      -- GC do something...
      print('--- robot __gc ---', t.pid)
    end
  })
  _M.robot:init({ uid = uid, pid = id })
  skynet.fork(function()
    loop(_M.robot)
    exit()
  end)
end

return {
  command = _M,
  require = {},
  init = function()
    math.random(util.time())
    client.init('s2c', 'c2s')
  end
}
