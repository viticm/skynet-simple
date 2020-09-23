--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id common.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/09/17 19:26
 - @uses Common actions.
--]]
local skynet = require 'skynet'
local client = require 'robot.client'
local action = require 'robot.action'
local log = require 'log'

-- Data.
-------------------------------------------------------------------------------

local _CH = client.handler
local _ARH = action.run_handler

-- Local functions.
-------------------------------------------------------------------------------

local function rand_move(self)
  local x = math.random(0, 512 - 1)
  local y = math.random(0, 512 - 1)
  self:send('move_to', {x = x, y = y})
  skynet.sleep(100)
end

-- Run handlers.
-------------------------------------------------------------------------------

function _ARH:test()
  print('action run test')
  for i = 1, 1000 do
    rand_move(self)
  end
end

-- Message.
-------------------------------------------------------------------------------

function _CH:move_to(msg)
  log:dump(msg, 'recv move to')
end
