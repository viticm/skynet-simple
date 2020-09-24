--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id handler.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/09/17 17:33
 - @uses The map handler.
--]]

local skynet = require 'skynet'
local laoi = require 'laoi'
local log = require 'log'
local e_error = require 'enum.error'

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

-- Move message.
function move_to(map, obj, msg)
  -- print('map handler move_to==========================', obj.id)
  obj:set_pos(msg)
  return { e = e_error.none }
end
