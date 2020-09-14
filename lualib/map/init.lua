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
    objs = {}
  }

  return setmetatable(t, { __index = _M })

end

function init(self)

end

-- Add a object.
function add(self, obj)
  self.objs[obj.id] =  obj
end

-- Get a object.
function get(self, id)
  return self.objs[id]
end

-- Remove a object.
function remove(self, id)
  self.objs[id] = nil
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
    obj = player.new(args)
    self:add(obj)
  else

  end
  log:info('map enter[%s] success', id)
  return e_error.none
end

function get_cfg(self)

end
