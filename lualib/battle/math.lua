--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id math.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/10/13 19:48
 - @uses The battle math tool.
         Current mode is 2d, use y replace z of vector3.
--]]

local util = require 'util'
local log = require 'log'
local vector3 = require 'vector3'
local e_skill = require 'enum.skill'

-- Local defines.
local math = math
local xpcall = xpcall
local pcall = pcall
local print = print
local next = next
local setmetatable = setmetatable

-- Data.
-------------------------------------------------------------------------------

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

function pos_distance(from, to)
  local x = from.x - to.x
  local y = from.y - to.y
  return math.sqrt(x^2 + y^2)
end

function distance(src, target)
  local x, y = src.x, src.y
  local x1, y1 = target.x, target.y
  return _M.pos_distance({x = x, y = y}, {x = x1, y = y1})
end

function in_shape(target, src_pos, dir, shape, args)
  local r = false
  if e_skill.shape_rect == shape then

  elseif e_skill.shape_cricle == shape then

  elseif e_skill.shape_sector == shape then

  elseif e_skill.shape_ring == shape then

  end
  return r
end

function in_range(src_pos, target_pos, range)

end

function in_rect(src_pos, target_pos, length, width, dir)

end

function in_sector(src_pos, target_pos, half_angle, dir)

end
