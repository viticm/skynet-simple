--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id preload.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/11/25 19:56
 - @uses The preload script.
--]]

print('preload')

--[[
local lreload = require 'debug.lua_reload'

function lreload.ShouldReload(fileName)
  print('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxfile:', fileName)
  return true
end

lreload.Inject()
--]]

local lreload = require 'debug.hot_update'

lreload.init(nil, nil, print)

_G.RELOAD = lreload
