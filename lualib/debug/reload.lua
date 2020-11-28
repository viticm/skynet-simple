--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id reload.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/11/25 10:33
 - @uses The debug reload module.
--]]

local skynet = require 'skynet'
local skynetdebug = require 'skynet.debug'

skynetdebug.reg_debugcmd('RELOAD', function(f)
  print('_G.RELOAD=================', _G.RELOAD)
  assert(_G.RELOAD, 'can not find reload environment!!!')
  _G.RELOAD.reload(f)
  return skynet.retpack(true)
end)
