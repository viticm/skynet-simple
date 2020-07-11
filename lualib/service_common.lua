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

local _M = {}

function _M.start()
  
  -- Proto load.
  local proto_loader = skynet.uniqueservice('proto_loader')
  skynet.call(proto_loader, 'lua', 'load', { 'c2s', 's2c' })

  -- Debug service.
  local dport = skynet.getenv('debugport')
  skynet.uniqueservice('debug_console', dport)

end

return _M
