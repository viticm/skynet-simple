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
local monster = require 'map.monster'
local e_error = require 'enum.error'
local cfg = require 'cfg'
local aoi = require 'map.aoi'

local type = type
local pairs = pairs
local string = string
local table = table
local math = math
local setmetatable = setmetatable
local print = print

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
    loop = 0,
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

  -- Create test monster.
  for i = 1, 10 do
    print('create monster', i)
    local x = math.random(1, map_cfg.width)
    local y = math.random(1, map_cfg.height)
    self:add_monster({ id = 1, x = x, y = y })
  end

end

-- Add a object.
-- @param table obj
-- @param mixed args
function add(self, obj, args)
  args = args or {}
  local aoi_id = self.aoi:unit_new({ x = obj.x, y = obj.y, id = obj.id })
  print('aoi_id=================', aoi_id)
  args.aoi_id = aoi_id
  obj:init(args)
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
    self:add(obj, args)
  else -- Some update.
    obj.fd = args.fd
  end
  log:info('map enter[%s] success', id)
  return e_error.none
end

function get_cfg(self)
  return cfg.get('map')[self.id]
end

-- Add a monster to map.
-- @param table conf The monster config.
-- @return mixed
function add_monster(self, conf)
  print('the require_ex===================', require_ex)
  local mcfg = cfg.get_row('monster', conf.id)
  if not mcfg then
    log:warn('add_monster can not find the config from: %d', conf.id)
    return
  end
  conf.cfg = mcfg
  local obj = monster.new(conf)
  obj.x = conf.x
  obj.y = conf.y
  self:add(obj, conf)
  log:debug('add_monster: %d|%d to [%d, %d]', conf.id, obj.id, obj.x, obj.y)
  return obj
end

-- Update self logic.
function update(self)
  self.loop = self.loop + 1
  if 0 == self.loop % 5 then
    local monsters = self.monsters
    for _, et in pairs(monsters) do
      et:update()
    end
  end
end

-- Exit a map object.
function exit(self)
  self.exited = true
end
