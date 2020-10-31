--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id init.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/09/07 19:25
 - @uses The map class.
--]]

local skynet = require 'skynet'
local log = require 'log'
local player = require 'map.player'
local e_error = require 'enum.error'
local cfg = require 'cfg'
local aoi = require 'map.aoi'

local tostring = tostring
local type = type
local pairs = pairs
local string = string
local table = table
local load = load
local pcall = pcall
local setmetatable = setmetatable
local print = print
local os = os

-- Data.
-------------------------------------------------------------------------------

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

-- API.
-------------------------------------------------------------------------------

function new(conf)

  local t = {
    id = conf.id,
    objs = {},                                  -- All object hash.
    players = {},                               -- All player object hash.
    monsters = {},
    npcs = {},
  }

  return setmetatable(t, { __index = _M })

end

function init(self)

  local map_cfg = self:get_cfg()

  -- AOI.
  local aoi_args = {}
  aoi_args.width = map_cfg.width
  aoi_args.height = map_cfg.height
  aoi_args.view = map_cfg.view
  self.aoi = aoi.new(aoi_args)

  -- Other objs create from config.

end

-- Add a object.
function add(self, obj)
  local aoi_id = self.aoi:unit_new({ x = obj.x, y = obj.y, id = obj.id })
  print('aoi_id=================', aoi_id)
  obj:init({ aoi_id = aoi_id })
  self.objs[obj.id] = obj

  if obj:is_player() then
    self.players[obj.id] = obj
  elseif obj:is_npc() then
    self.npcs[obj.id] = obj
  elseif obj:is_monster() then
    self.monsters[obj.id] = obj
  end

  -- Appear.
  local name, msg = obj:pack_appear()
  obj:send_around(name, msg)
end

-- Get a object.
function get(self, id)
  return self.objs[id]
end

-- Remove a object.
function remove(self, id)

  local obj = self.objs[id]
  if not obj then return end

  if obj:is_player() then
    self.players[obj.id] = nil
  elseif obj:is_npc() then
    self.npcs[obj.id] = nil
  elseif obj:is_monster() then
    self.monsters[obj.id] = nil
  end

  -- Disappear.
  local name, msg = obj:pack_disappear()
  obj:send_around(name, msg)

  self.objs[id] = nil
  self.aoi:unit_del(id)
end

-- The enter.
-- @param mixed args The enter args.
-- @return number
function enter(self, args)
  local id = args.id
  if not id then
    log:warn('enter not found player id')
    return e_error.invalid_operation
  end
  local obj = self:get(id)
  if not obj then
    args.map = self
    obj = player.new(args)
    obj:init(args)
    self:add(obj)
  else

  end
  log:info('map enter[%s] success', id)
  return e_error.none
end

function get_cfg(self)
  return cfg.get('map')[self.id]
end

function update(self)

end
