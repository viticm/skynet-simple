--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id base.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/09/07 13:53
 - @uses The player base module.
--]]

local skynet = require 'skynet'
local mod = require 'world.role.mod'
local cache = require 'mysql.cache'
local log = require 'log'

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


-- Data.
-------------------------------------------------------------------------------

local nm = 'base'
mod(nm, _M)

-- API(self is the role object).
-------------------------------------------------------------------------------

function load(self)
  local rid = self.id
  self[nm] = cache.load(rid, nm)

  log:dump(self[nm], 'base load===================')
end

function enter(self)
  print('base enter==============================', self.id)
end
