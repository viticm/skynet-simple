--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id map_mgr.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/09/07 19:32
 - @uses The map manager service.
         map_mgr(service map/manager)->map(service map/init)
--]]

local skynet = require 'skynet'
local service_pool = require 'service_pool'
local mgr = require 'map.manager'

-- Data.
-------------------------------------------------------------------------------

local _M = {}

-- Local functions.
-------------------------------------------------------------------------------

-- The service init.
local function init()
  mgr.init()
end

-- The service release.
local function release()

end

-- API.
-------------------------------------------------------------------------------

-- Enter a map.
-- @param number id The map config id.
-- @param number line The map line no.
-- @param table args
-- @return mixed
function _M.enter(id, line, args)
  return mgr.enter(id, line, args)
end

-- Other.

return {
  init = init,
  command = _M
}
