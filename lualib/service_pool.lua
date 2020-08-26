--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id service_pool.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/20 20:22
 - @uses The service pool generate tool.
--]]

local skynet = require 'skynet'

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

_VERSION = "0.0.1"

-- API.
-------------------------------------------------------------------------------

-- New a pool.
-- @param table conf {
-- max = number,  -- The service max count.
-- cap = number,  -- One service cap.
-- def = number,  -- The service default count.
-- boot = string, -- The service boot startup file name.
-- }
function new(conf)
  local t = {
    max = conf.max or 99,
    cap = conf.cap or 999,
    def = conf.def or 5,
    hash = {},  -- The hash key list.
    list = {},  -- The service list {addr, count}.
    free = 1,   -- The free service index, must be the min index.
    boot = conf.boot,
  }
  for i = 1, t.def do
    local addr = skynet.newservice(t.boot)
    local s = { addr = addr, count = 0 }
    table.insert(t.list, s)
  end
  return setmetatable(t, { __index = _M })
end

-- Get a service addr by hash id.
-- @param mixed hid Hash id.
-- @return mixed
function get(self, hid)
  local hash = self.hash
  local list = self.list
  if hash[hid] then
    local s = list[hash[hid]]
    return s and s.addr
  end
  if self.free then
    local s = list[self.free]
    if not s then return end
    hash[hid] = self.free
    s.count = s.count + 1
    if s.count >= self.cap and self.free < #list then -- Find next free index.
      local find_free
      for i = self.free + 1, #self.list do
        s = list[i]
        if s.count < self.cap then
          find_free = i
          break
        end
      end
      self.free = find_free
    end
    return list[self.free].addr
  else
    if #list >= self.max then
      return
    end
    local addr = skynet.newservice(self.boot)
    local s = { addr = addr, count = 0 }
    table.insert(list, s)
    hash[hid] = #list
    s.count = 1
    return hash[hid]
  end
end
