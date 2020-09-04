--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id main.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/19 17:08
 - @uses The world server bootstarup script.
--]]

local skynet = require 'skynet'
local skynet_manager = require 'skynet.manager'
local cfg = require 'cfg.loader'
local setting = require 'setting'
local service_common = require 'service_common'

local function init()
  skynet.error('--- world server starting ---')

  service_common.start()

  local db_mgr = skynet.uniqueservice('db_mgr')
  skynet.name('db_mgr', db_mgr)

  local manager = skynet.uniqueservice('world/manager')
  skynet.name('.manager', manager)

  skynet.call(manager, 'lua', 'open', {
    address = setting.get('ip') or '0.0.0.0',
    port = setting.get('port'),
    client_max = setting.get('client_max') or 3000,
    no_delay = true,
    recvspeed = 30,
  })

  skynet.call('.launcher', 'lua', 'FINISHBOOT')

  skynet.error('-- world server startup complated ---')
  skynet.exit()
end

return {
  init = init,
}
