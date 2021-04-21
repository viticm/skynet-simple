--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id reload_cfg.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2021 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2021/04/21 14:30
 - @uses Reload config file.
--]]
local skynet = require 'skynet'
local log = require "log"

-- Local functions.
-------------------------------------------------------------------------------
local function init(f)
  local list = skynet.call('.launcher', 'lua', 'LIST')
  log:info('start reload config(%s)', f)
  for addr in pairs(list) do
    local ok, r =
      pcall(skynet.call, addr, 'debug', 'RUN', 'require "debug.reload_cfg"')
    if not ok then
      skynet.error(r)
    else
      ok, r = pcall(skynet.call, addr, 'debug', 'RELOAD_CFG', f)
      if not ok then
        skynet.error(r)
      else
        skynet.error(string.format('%s reload_cfg(%s) succeed', addr, f))
      end
    end
  end
  log:info('reload config(%s) finished', f)
  skynet.exit()
end

return {
  init = init
}
