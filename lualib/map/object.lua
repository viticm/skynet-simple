--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id object.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/09/07 20:24
 - @uses The map object class.
        cn: 所有自身的观察者对象列表可以放在对象身上作为换成维护，可以节省一些查
        询时间
--]]

local skynet = require 'skynet'
local log = require 'log'
local attr = require 'battle.attr'
local skill = require 'battle.skill'
local buff = require 'battle.buff'

local e_object_type = require 'enum.object_type'

local type = type
local pairs = pairs
local ipairs = ipairs
local setmetatable = setmetatable
local print = print
local next = next

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
    aoi_id = conf.aoi_id,
    x = conf.x,
    y = conf.y,
    map = conf.map,
    viewers = nil,                  -- All can see object id hash.
  }
  if not conf.no_battle then
    t.attr = attr.new({ et = t })
    t.skill = skill.new({ et = t })
    t.buff = buff.new({ et = t })
  end
  return setmetatable(t, { __index = _M })
end

function init(self, args)
  if args.aoi_id then
    self.aoi_id = args.aoi_id
  end
end

function is_player(self)
  return e_object_type.player == self.tp
end

function is_npc(self)
  return e_object_type.npc == self.tp
end

function is_monster(self)
  return e_object_type.monster == self.tp
end

-- AOI update pos.
function aoi_update(self)
  if not self.aoi_id or not self.map then return end
  self.map.aoi:update(self.aoi_id, { self.x, self.y })
end

-- The appear package.
function pack_appear(self)
  local msg = {
    id = self.id,
    name = self.name,
    tp = self.tp,
    x = self.x,
    y = self.y,
    dir = self.dir
  }
  return "map_object", msg
end

-- The disappear package.
function pack_disappear(self)
  local msg = {
    id = self.id,
    name = self.name,
    tp = self.tp,
  }
  return "unmap_object", msg
end

-- Send a message to around object.
-- @param string name Package name.
-- @param table msg Package data.
function send_around(self, name, msg)
  local objs = self:get_viewers()
  for id in pairs(objs or {}) do
    local obj = self.map.objs[id]
    print('send_around obj======================', obj and obj.id)
    local _ = obj and obj.send and obj:send(name, msg)
  end
end

-- Set position.
-- @param table args
function set_pos(self, args)
  self.x = args.x
  self.y = args.y
  self.dir = args.dir
  -- print('set_pos===============', self.x, self.y, self.dir)
  self:aoi_update()
end

-- Update aoi.
function aoi_update(self)
  -- Update AOI.
  -- print('self.aoi_id===========', self.aoi_id, self.map and self.map.aoi and self.map.aoi.view)
  local view = self.map and self.map.aoi and self.map.aoi.view
  if self.aoi_id and view then
    local args = { id = self.aoi_id, x = self.x, y = self.y }
    local ins, outs = self.map.aoi:unit_update(args)
    if ins and next(ins) then
      local name, msg = self:pack_appear()
      for _, id in ipairs(ins) do
        print('in id=============================', id, self.id)
        local obj = self.map.objs[id]
        if obj then
          if obj.send and not obj.viewers[self.id] then
            print('send to obj:', obj.id)
            obj.viewers[self.id] = 1
            obj:send(name, msg)
          end
          if self.send and not self.viewers[obj.id] then
            print('send to self:', self.id)
            self.viewers[obj.id] = 1
            self:send(obj:pack_appear())
          end
        end
      end
    end
    if outs and next(outs) then
      local name, msg = self:pack_disappear()
      for _, id in ipairs(outs) do
        print('out id=============================', id, self.id)
        local obj = self.map.objs[id]
        if obj then
          if obj.send and obj.viewers[self.id] then
            obj.viewers[self.id] = nil
            obj:send(name, msg)
          end
          if self.send and self.viewers[obj.id] then
            self.viewers[obj.id] = nil
            self:send(obj:pack_disappear())
          end
        end
      end
    end
  end
end

-- Get me can see viewers.
-- @return mixed
function get_viewers(self)
  if not self.aoi_id or not self.map then return end
  local aoi = self.map.aoi
  if not aoi then return end
  if not aoi.view then
    return self.map.players
  else
    if self.viewers then return self.viewers end
    self.viewers = {}
    local ids = aoi:unit_search({ id = self.aoi_id, range = aoi.view })
    for _, id in ipairs(ids) do
       self.viewers[id] = 1
    end
    return self.viewers
  end
end

-- If self can be attack by input object.
-- @param table et Input entity object.
-- @return bool
function can_attacked(self, et)
  if et:is_npc() then return false end
  return true
end

-- Change self hp.
-- @param number hp The change hp.
-- @param mixed args
function change_hp(self, hp, args)
  args = args or {}
  local cur_hp = self.attr:get('hp')
  local hpmax = self.attr:get('hpmax')
  local final = cur_hp + hp
  if final < 0 then
    final = 0
  elseif final > hpmax then
    final = hpmax
  end
  self.attr:set('hp', final)
  if 0 == final then
    self:on_death(self, args)
  end
end

-- Events.
-------------------------------------------------------------------------------

function on_death(self, args)
  local target = args.target
  print('on_death=======================', target and target.id)
end
