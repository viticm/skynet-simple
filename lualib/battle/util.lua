--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id util.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/10/15 09:50
 - @uses The battle util tool.
--]]

local util = require 'util'
local log = require 'log'
local cfg = require 'cfg'

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

-- API.
-------------------------------------------------------------------------------

-- Search entity from shape.
function search_entity(et, pos, dir, shape, args)

end

-- Config --

function get_effects(id)
  local conf = cfg.get('skill')
  return conf[id] and conf[id].effects
end

function get_skill_cfg(id)
  local conf = cfg.get('skill')
  return conf[id]
end

function get_buff_cfg(id)
  local conf = cfg.get('buff')
  return conf[id]
end
