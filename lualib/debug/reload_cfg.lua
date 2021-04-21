--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id reload_cfg.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2021 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2021/04/21 14:26
 - @uses Reload config file.
--]]
local skynet = require 'skynet'
local skynetdebug = require 'skynet.debug'
local cfg = require "cfg"

skynetdebug.reg_debugcmd('RELOAD_CFG', function(f)
  -- print("before:", cfg.get(f)[3])
  cfg.reload(f)
  -- print("after:", cfg.get(f)[3])
  return skynet.retpack(true)
end)
