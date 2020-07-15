--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id base.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/07/09 17:24
 - @uses The base service for all server.
--]]

local skynet = require "skynet"
local sharetable = require "skynet.sharetable"
local setting = require "setting"
local log = require "log"

local _M = {}

function _M.start()

  -- Setting.
  local def_setting = dofile('bin/def_setting.lua')
  setting.init(def_setting)
  
  -- Proto load.
  local proto_loader = skynet.uniqueservice('proto_loader')
  skynet.call(proto_loader, 'lua', 'load', { 'c2s', 's2c' })

  -- Debug service.
  local dport = skynet.getenv('debugport')
  skynet.uniqueservice('debug_console', dport)

  log:error('the error log')
  log:warn('the warn log')
  log:info('the info log')
  log:debug('the debug log')

end

return _M
