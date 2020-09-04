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
-- @param mixed not_alloc Not alloc new when hasn't alloc.
-- @return mixed
function get(self, hid, not_alloc)
  local hash = self.hash
  local list = self.list
  if hash[hid] then
    local s = list[hash[hid]]
    return s and s.addr
  end
  if not_alloc then return end
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

-- Foreach all service item.
-- @param function func The foreach function handle (addr, index, ...)
function foreach(self, func, ...)
  for index, info in ipairs(self.list) do
    func(info.addr, index, ...)
  end
end

-- Stop all service in pool.
function stop(self)
  for index, info in ipairs(self.list) do
    skynet.send(info.addr, 'lua', 'stop')
  end
end

-- Reload one file.
-- @param string filename
function reload(self, filename)
  for index, info in ipairs(self.list) do
    skynet.send(info.addr, 'lua', 'reload', filename)
  end
end

-- Garbage collect(keep one alive full free service when service more than def).
function gc(self)
  local count = #self.list
  local frees = {}
  for i = count, self.def + 1, -1 do
    local info = self.list[i]
    if 0 == info.count then
      table.insert(frees, i)
    else
      break
    end
  end
  if #frees <= 1 then return end
  for i = 1, i < #frees -1 do
    local index = frees[i]
    local info = self.list[index]
    log:info('gc index %d', index)
    skynet.send(info.addr, 'lua', 'stop')
    table.remove(self.list, index)
  end
end

-- Send a message to all service.
function broadcast(self, name, ...)
  for _, info in ipairs(self.list) do
    skynet.send(info.addr, 'lua', name, ...)
  end
end

-- Free an service use count.
-- @param number index The hash id.
function free(self, hid)
  local index = hash[hid]
  if not index then return end
  local info = self.list[index]
  if info then
    info.count = info.count - 1
  end
  hash[hid] = nil
  self:gc()
end
