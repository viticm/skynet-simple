--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id main.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2021/03/26 16:22
 - @uses The cross server bootstarup script.
--]]

local skynet = require 'skynet'
local skynet_manager = require 'skynet.manager'
local cfg_loader = require 'cfg.loader'
local setting = require 'setting'
local service_common = require 'service_common'

local function init()
  skynet.error('--- cross server starting ---')

  service_common.start()

  local stype = skynet.getenv('svr_type')
  cfg_loader.loadall(stype)

  local db_mgr = skynet.uniqueservice('db_mgr')
  skynet.name('db_mgr', db_mgr)

  local map_mgr = skynet.uniqueservice('map_mgr')
  skynet.name('.map_mgr', map_mgr)

  skynet.call('.launcher', 'lua', 'FINISHBOOT')

  skynet.error('-- cross server startup complated ---')
  skynet.exit()
end

return {
  init = init,
}
