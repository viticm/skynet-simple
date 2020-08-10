--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id main.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/07/09 17:06
 - @uses The login server main script.
--]]

local skynet = require 'skynet'
local cluster = require 'skynet.cluster'
local service_common = require 'service_common'
local setting = require 'setting'

local function init()
  skynet.error('** login server starting **')

  service_common.start()

  local auth_mgr = skynet.uniqueservice('login/auth_mgr')
  cluster.register('auth_mgr', auth_mgr)

  local count = setting.get('auth_count')
  local ip = setting.get('net_ip')
  local port = setting.get('port')

  skynet.call(auth_mgr, 'lua', 'start_auth', count)
  skynet.call(auth_mgr, 'lua', 'start_gate', ip, port)

  skynet.call('.launcher', 'lua', "FINISHBOOT")
  skynet.error('--- login server startup complete. ---')
  skynet.exit()
end

return {
  init = init
}
