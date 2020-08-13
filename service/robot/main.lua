--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id main.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/10 10:38
 - @uses The robot boot script.
--]]

local skynet = require 'skynet'
local cfg_loader = require 'cfg.loader'
local setting = require 'setting'
local util = require 'util'

-- Local functions.
-------------------------------------------------------------------------------

local function init()
  skynet.error('--- robot starting ---')
  
  -- local def_set = dofile('bin/def_setting')
  -- setting.init(def_set)

  -- Proto files.
  local proto_s = skynet.uniqueservice 'proto_loader'
  skynet.call(proto_s, 'lua', 'load', {'c2s', 's2c'})

  local stype = skynet.getenv('svr_type')

  -- Config.
  cfg_loader.loadall(stype)

  if not skynet.getenv('daemon') then
    skynet.uniqueservice 'console'
  end

  local start = skynet.getenv('svr_start')
  local num = skynet.getenv('svr_num')
  local mod = skynet.getenv('svr_mod')
  local id = skynet.getenv('svr_id')

  -- The setting.
  local sets = dofile(string.format('bin/setting/robot/%d.lua', id))
  setting.init(sets)

  -- Mode.
  local mod_array = util.split(mod, ':')
  local run_mod = { name = mod_array[1] }
  table.remove(mod_array, 1)
  if #mod_array > 0 then
    run_mod.no_login = util.in_array(mod_array, 'no_login')
    run_mod.rand = util.in_array(mod_array, 'rand')
    run_mod.once = util.in_array(mod_array, 'once')
  end
  setting.set('run_mod', run_mod)

  skynet.error('robot start = ', start, ' num = ', num)
  for i = start, start + num - 1 do
    local agent = skynet.uniqueservice 'robot/agent'
    skynet.send(agent, 'lua', 'init', id)
  end

  -- Finsh.
  skynet.error('--- robot startup complete. ---')
  skynet.exit()

end

return {
  init = init
}
