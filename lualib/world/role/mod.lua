--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id mods.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/09/04 17:13
 - @uses The role mods tool.
--]]

local skynet = require 'skynet'
local cache = require 'mysql.cache'

-- Enviroment.
-------------------------------------------------------------------------------

local table = table
local setmetatable = setmetatable
local ipairs = ipairs
local print = print

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

-- Data.
-------------------------------------------------------------------------------

names = names or {}   -- The name sort list.
hash = hash or {}     -- The mod table hash [name] = table.

-- Local functions.
-------------------------------------------------------------------------------

local function call(fn, ...)
  for _, name in ipairs(names) do
    local mod = hash[name]
    local f = mod[fn]
    if f then
      local start_t = skynet.now()
      f(...)
      local cost_t = skynet.now() - start_t
      if cost_t > 100 then
        skynet.error('mod[%s] call[%s] cost time[%d]', name, fn, cost_t)
      end
    end
  end
end

local function reg(n, m)
  if not hash[n] then
    table.insert(names, n)
  end
  hash[n] = m
end

setmetatable(_M, {
  __call = function(t, n, m)
    reg(n, m)
  end
})

-- API.
-------------------------------------------------------------------------------

function load(role)
  local rid = role.id
  local db_proxy = role.db_proxy
  if not role.mods_loaded then
    cache.init('t_mod_', rid, db_proxy)
    print('cache.init', rid, db_proxy)
    role.mods_loaded = true
  end
  call('load', role)
end

function enter(role)
  call('enter', role)
end

function after_enter(role)
  call('after_enter', role)
end

function unload(role)
  call('unload', role)
  cache.unload(role.id)
  role.mods_loaded = nil
end
