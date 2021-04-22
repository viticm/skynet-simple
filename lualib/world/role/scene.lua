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
local cfg = require 'cfg'
local cache = require 'mysql.cache'
local client = require 'client'
local server = require 'server'
local log = require 'log'
local e_error = require 'enum.error'

-- Enviroment.
-------------------------------------------------------------------------------

local _CH = client.handler()
local print = print
local table = table

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

local map_one

-- Local functions.
-------------------------------------------------------------------------------

local function rebuild_map_cfg()
  map_one = cfg.get("map")[3]
end

-- API(self is the role object).
-------------------------------------------------------------------------------

function enter_map(self)
  print('scene enter==============================', self.id, self.fd, map_one)
  local base = self.base
  local map = base.map or {}
  local id = map.id or 1
  local line = map.line
  local x, y = map.x, map.y
  local map_cfg = cfg.get('map')[id]
  if not x or not y then
    x, y = table.unpack(map_cfg.born)
  end
  local args = { x = x, y = y, id = self.id, fd = self.fd }
  local r, addr
  local node = server.node
  if map_cfg.is_cross then

  else
    r, addr, line = skynet.call('.map_mgr', 'lua', 'enter', id, line, args)
  end
  if e_error.none ==  r then
    self.map_addr = addr
    base.map = base.map or {}
    base.map.id = id
    base.map.line = line
    base.map.node = node
    cache.dirty(self.id, 'base')
    print('enter_map success11111111111111111111111111111111')
  end
  return r
end

-- Client message.
-------------------------------------------------------------------------------

function _CH:move_to(msg)
  -- log:dump(msg)
  return self:call_map('move_to', msg)
end

skynet.init(function()
  cfg.rebuild("map", rebuild_map_cfg)
end)
