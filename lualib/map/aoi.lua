--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id aoi.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/09/15 19:35
 - @uses The map aoi class.
          cn: 目前AOI使用的三方库为四叉树实现，而源码的实现中单元ID最大为int，
              因此目前在构建这个对象时需要把单元ID和对象索引做一个哈希，有考虑
              改动三方库源码将对象ID集成在其中可能节省少许内存和在搜索查询时少
              一些构建操作
--]]

local skynet = require 'skynet'
local laoi = require 'laoi'
local log = require 'log'

-- Data.
-------------------------------------------------------------------------------

local pairs = pairs
local ipairs = ipairs
local string = string
local table = table
local load = load
local pcall = pcall
local setmetatable = setmetatable
local print = print
local math = math

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

-- Local functions.
-------------------------------------------------------------------------------

-- API.
-------------------------------------------------------------------------------

-- New a aoi object.
function new(conf)
  local t = {
    cur = 0,
    map = nil,
    view =  conf.view,      -- The view radius
    width = conf.width,
    height = conf.height,
    ids = {},               -- [unit id] = object id
    frees = {},             -- Collect free ids.
    x = conf.x,
    y = conf.y,
    divide = conf.divide or 6
  }
  t.map = laoi.new_map({ t.width, t.height }, t.divide, { t.x, t.y })
  return setmetatable(t, { __index = _M })
end

-- New a unit object to map.
-- @param table args
-- @return number
function unit_new(self, args)
  local id
  if #self.frees > 0 then
    id = self.frees[1]
    table.remove(self.frees, 1)
  else
    self.cur = self.cur + 1
    id = self.cur
  end
  print('id=======================', id, args.x, args.y)
  local unit = laoi.new_unit(id, { args.x, args.y })
  self.map:unit_add(unit)
  if args.id then -- Object id.
    self.ids[id] = args.id
  end
  return id
end

-- Delete a unit object from map.
-- @param number id
function unit_del(self, id)
  self.map:unit_del_by_id(id)
  table.insert(self.frees, id)
end

-- Update a unit.
-- @param table args
-- @return ins?, outs?
function unit_update(self, args)
  local ins, outs, before, after
  local unit = self.map:get_units()[args.id]
  if not unit then return end
  if self.view then
    ins, outs = {}, {}
    before = self.map:unit_search(unit, self.view) -- self:unit_search(args)
  end
  local _ = unit and self.map:unit_update(unit, { args.x, args.y })
  if self.view then
    after = self.map:unit_search(unit, self.view) -- self:unit_search(args)
    for id in pairs(before) do
      if not after[id] then
        table.insert(outs, self.ids[id])
      end
    end
    for id in pairs(after) do
      if not before[id] then
        table.insert(ins, self.ids[id])
      end
    end
    print('unit_update=============', #ins, #outs)
  end
  return ins, outs
end

-- Unit search(return object ids).
-- @param table args
-- @return table
function unit_search(self, args)
  local r = {}
  local unit = self.map:get_units()[args.id]
  if not unit then return r end
  local units = self.map:unit_search(unit, args.range)
  for id in pairs(units) do
    table.insert(r, self.ids[id])
  end
  return r
end

-- Search circle(return object ids).
-- @param table args
-- @return table
function search_cricle(self, args)
  local units = self.map:search_circle(args.range, { args.x, args.y })
  local r = {}
  for id in pairs(units) do
    table.insert(r, self.ids[id])
  end
  return r
end
