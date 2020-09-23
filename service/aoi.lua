--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id aoi.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/09/15 14:37
 - @uses The aoi service(now 3rd is not use service do update).
--]]

local skynet = require 'skynet'
local aoi = require 'laoi'

-- Data.
-------------------------------------------------------------------------------

local _M = {}
local map
local ids = {}          -- [unit id] = object id

-- Local functions.
-------------------------------------------------------------------------------

local function init()

end

-- API.
-------------------------------------------------------------------------------


return {
  init = init,
  command = _M,
}
