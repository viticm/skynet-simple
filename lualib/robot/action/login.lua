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
local action = require 'robot.action'

-- Data.
-------------------------------------------------------------------------------

local _RH = client.handler
local _ARH = action.run_handler

-- Local functions.
-------------------------------------------------------------------------------


-- Run handlers.
-------------------------------------------------------------------------------

-- Auto login action.
function _ARH:auto_login(cfg, args)
  _ARH.discon(self, cfg, {})
  if not args.logined then
    args.logined = self:login_account()
  else
    args.ended = self:login_game()
  end
end

-- Disconnect.
function _ARH:discon(cfg, args)
  args.ended = true
  if self.fd then
    self:close()
  end
  self.entered = nil
  skynet.sleep(20)
end

-- Message.
-------------------------------------------------------------------------------

-- Role list.
function _RH:roles(msg)
  self.roles = msg.list
  log:dump(msg.list, 'self.roles======================')
end
