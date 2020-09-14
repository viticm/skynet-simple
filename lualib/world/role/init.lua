--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id init.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/28 16:12
 - @uses The role class on world agent.
--]]

local skynet = require 'skynet'
local socket = require 'skynet.socket'
local client = require 'client'

require 'world.role.load' -- Load all role script(mods)

-- Enviroment.
-------------------------------------------------------------------------------

local setmetatable = setmetatable

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

handler = handler or {}

-- API.
-------------------------------------------------------------------------------

-- Create new role.
-- @param table data The role data.
function new(data)
  local t = {
    id = data.id,
    fd = data.fd,
    db_loaded = nil,
    addr = data.addr,
    gate = data.gate,
    sname = data.sname,
    auth = data.auth,
    platform = data.platform
  }
  return setmetatable(t, { __index = _M })
end

-- Init.
function init(self)

end

-- Send message to client.
-- @param string name Message name.
-- @param table msg Message data.
function send(self, name, msg)
  if not self.fd or sokect.invalid(self.fd) then
    return
  end
  client.push(self, name, msg)
end


