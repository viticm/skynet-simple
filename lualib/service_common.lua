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

local skynet = require 'skynet'
local sharetable = require 'skynet.sharetable'
local setting = require 'setting'
local setting_loader = require 'setting.loader'
local log = require 'log'

local _M = {}

function _M.start()

  -- Setting.
  local def_setting = dofile('bin/setting/default.lua')
  setting.init(def_setting)
  
  -- Proto load.
  local proto_loader = skynet.uniqueservice('proto_loader')
  skynet.call(proto_loader, 'lua', 'load', { 'c2s', 's2c' })

  local stype = skynet.getenv('svr_type')
  local sid = skynet.getenv('svr_id')

  -- Platform settings.
  setting_loader.load_platform(stype, sid)

  print('setting port', setting.get('port'))

  local port = setting.get('port')

  -- Debug service.
  local dport = setting.get('dport') or (port + 10000)
  local fp = assert(io.open(skynet.getenv('dport_file'), 'w'))
  fp:write(dport)
  fp:close()
  skynet.uniqueservice('debug_console', dport)

  log:error('the error log')
  log:warn('the warn log')
  log:info('the info log')
  log:debug('the debug log')
  log:dump({'ccc', {a = 1}, 3}, "the test table")

end

return _M
