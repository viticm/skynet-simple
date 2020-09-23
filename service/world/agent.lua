--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id agent.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/21 19:52
 - @uses The world agent.
--]]

local skynet = require 'skynet'
local service_provider = require 'service_provider'
local client = require 'client'
local role_mgr = require 'world.role_mgr'

local _M = {}

skynet.register_protocol {
  name = 'client',
  id = skynet.PTYPE_CLIENT,
  unpack = function(...) return ... end,
  pack = function() return 'NOT RET' end
}

return {
  command = _M,
  dispatch = {
    lua = function(session, source, cmd, rid, ...)
      print("on lua msg=========================")
      role_mgr.on_lua_msg(session, cmd, rid, ...)
    end,
    client = function(fd, address, msg, sz)
      skynet.ignoreret()
      role_mgr.on_client_msg(fd, msg, sz)
    end
  },
  init = function()
    client.init('c2s', 's2c')
    role_mgr.init()
  end,
  info = role_mgr.info,
  release = nil
}
