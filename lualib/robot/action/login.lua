--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id login.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/31 19:49
 - @uses The robot login action mod.
--]]

local skynet = require 'skynet'
local client = require 'robot.client'
local log = require 'log'

-- Data.
-------------------------------------------------------------------------------

local _RH = client.handler

-- Message.
-------------------------------------------------------------------------------

-- Role list.
function _RH:roles(msg)
  self.roles = msg.list
  log:dump(msg.list, 'self.roles======================')
end
