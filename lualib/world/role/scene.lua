--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id scene.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/09/04 19:23
 - @uses The scene module.
--]]

local skynet = require 'skynet'
local cache = require 'mysql.cache'
local e_error = require 'enum.error'

-- Enviroment.
-------------------------------------------------------------------------------

local print = print
local table = table

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

-- API(self is the role object).
-------------------------------------------------------------------------------

function enter_map(self)
  print('scene enter==============================', self.id)
  local base = self.base
  local map = base.map or {}
  local id = map.id or 1
  local line = map.line
  local x, y = map.x, map.y
  local args = { x = x, y = y, id = self.id }
  local r, addr, line = skynet.call('.map_mgr', 'lua', 'enter', id, line, args)
  if e_error.none ==  r then
    base.map = base.map or {}
    base.map.id = id
    base.map.line = line
    cache.dirty(self.id, 'base')
    print('enter_map success11111111111111111111111111111111')
  end
  return r
end
