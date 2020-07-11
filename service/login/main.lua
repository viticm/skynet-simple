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
local service_common = require 'service_common'

local function init()
  skynet.error('** login server starting **')

  service_common.start()

end

return {
  init = init
}
