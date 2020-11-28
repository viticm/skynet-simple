--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id reload.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/11/25 10:16
 - @uses The reload service.
--]]

local skynet = require 'skynet'

-- Local functions.
-------------------------------------------------------------------------------

local function init(f)
  local list = skynet.call('.launcher', 'lua', 'LIST')
  skynet.error('start reload', f)
  for addr in pairs(list) do
    local ok, r =
      pcall(skynet.call, addr, 'debug', 'RUN', 'require "debug.reload"')
    if not ok then
      skynet.error(r)
    else
      ok, r = pcall(skynet.call, addr, 'debug', 'RELOAD', f)
      if not ok then
        skynet.error(r)
      else
        skynet.error(string.format('%s reload(%s) succeed', addr, f))
      end
    end
  end
  skynet.exit()
end

return {
  init = init
}
