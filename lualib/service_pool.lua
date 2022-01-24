--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id service_pool.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2022 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2022/01/20 11:57
 - @uses The service pool.
--]]

local skynet = require 'skynet'
local queue = require 'skynet.queue'
local log = require 'log'

local type = type
local pairs = pairs
local table = table
local setmetatable = setmetatable
local print = print
local next = next
local math = math

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

-- Local function.
-------------------------------------------------------------------------------

-- Create a new service.
-- return [addr? no? sub?]
local function newservice(self)
  print('newservice====================', #self.list, self.max)
  if #self.list >= self.max then
    return
  end
		if self.count >= self.max then
      local no = math.random(1, self.count)
      local s = self.list[no]
      local addr, sub
      if s then
        s.count = s.count + 1
        addr = s.addr
        sub = s.count
      end
      return addr, no, sub
		end
  print('newservice====================', #self.list, self.max)
  local no = self.count + 1
  if next(self.free_nos) then
    no = table.remove(self.free_nos, 1)
  end
  local addr = skynet.newservice(self.boot, self.boot_arg, no)
  local s = { addr = addr, count = 1, no = no }
  self.list[no] = s
  self.count = self.count + 1
  self.usable_nos[no] = 1
  return addr, no, 1
end

local function findservice(self)
  if next(self.usable_nos) then
    local no = next(self.usable_nos)
    local s = self.list[no]
    s.count = s.count + 1
    if s.count >= self.cap then
      self.usable_nos[no] = nil
    end
    return s.addr, no, s.count
  end
  return newservice(self)
end


-- API.
-------------------------------------------------------------------------------

-- New a pool.
-- @param table conf {
-- max = number,    -- The service max count.
-- cap = number,    -- One service cap.
-- def = number,    -- The service default count.
-- boot = string,   -- The service boot startup file name.
-- boot_args = mixed, -- The service boot startup extend args.
-- }
function new(conf)
  local t = {
    max = conf.max or 99,
    cap = conf.cap or 999,
    def = conf.def or 5,
    hash = {},      -- The hash key list[hid] = {index}.
    list = {},      -- The service list {addr, count} [no] = {}.
    free_nos = {},    -- The service can use nos.
    usable_nos = {},  -- The service not full service no hash.
    count = 0,      -- The current service count.
    new_queue = queue(),
    boot = conf.boot,
    new_count = 0,
    boot_arg = conf.boot_arg or -1
  }
  for i = 1, t.def do
    t.new_queue(newservice, t, true)
  end
  t.count = t.def

  if t.list[1] then
    t.usable = 1
  end
  return setmetatable(t, { __index = _M })
end

-- Get a service addr by hash id.
-- @param mixed hid Hash id.
-- @param mixed alloc Alloc new when hasn't alloc.
-- @return addr?, no?, sub?
function get(self, hid, alloc)
  local hash = self.hash
  local list = self.list
  if hash[hid] then
    local info = hash[hid]
    local no, sub = info.no, info.sub
    local s = self.list[no]
    return s and s.addr, no, sub
  end
  if not alloc then return end
  self.new_count = self.new_count + 1
  log.error('self.new_count========================', self.new_count)
  local usable = next(self.usable_nos)
  if usable then
    local s = list[usable]
    local addr = s.addr
    s.count = s.count + 1
    local sub = s.count
    hash[hid] = { no = s.no, sub = sub }
    print('no=================', s.no, s.count, s.addr)
    if s.count >= self.cap then
      self.usable_nos[usable] = nil
    end
    return addr, s.no, sub
  else
    local addr, no, sub = self.new_queue(findservice, self)
    self.hash[hid] = { no = no, sub = sub}
    return addr, no, sub
  end
end

-- Get service hash.
-- @param mixed hid The hash id.
-- @return mixed
function get_hash(self, hid)
  return self.hash[hid]
end

-- Foreach all service item.
-- @param function func The foreach function handle (addr, no, ...)
function foreach(self, func, ...)
  for no, info in pairs(self.list) do
    func(info.addr, no, ...)
  end
end

-- Stop all service in pool.
function stop(self)
  for _, info in pairs(self.list) do
    skynet.send(info.addr, 'lua', 'stop')
  end
end

-- Reload one file.
-- @param string filename
function reload(self, filename)
  for _, info in pairs(self.list) do
    skynet.send(info.addr, 'lua', 'reload', filename)
  end
end

-- Garbage collect(keep one alive full usable service when service more than def).
function gc(self)
  local usables = {}
  for no, info in pairs(self.list) do
    if 0 == info.count then
      table.insert(usables, no)
    end
  end
  local count = #usables
  if count <= 1 then return end
  for i, no in ipairs(usables) do
    if i == count then break end
    self:del(no)
  end
end

-- Remove a service by no.
function del(self, no)
  local s = self.list[no]
  log.info('service_pool del no', no)
  skynet.send(s.addr, 'lua', 'stop')
  self.list[no] = nil
  self.usable_nos[no] = nil
  self.count = self.count - 1
  table.insert(self.free_nos, no)
end

-- Remove a service safe by no.
function safe_del(self, no)
  local s = self.list[no]
  if not s or s.count > 0 then return end
  self:del(no)
end

-- Send a message to all service.
function broadcast(self, name, ...)
  for _, info in pairs(self.list) do
    skynet.send(info.addr, 'lua', name, ...)
  end
end

-- Free an service use count.
-- @param number hid The hash id.
function free(self, hid)
  local hash = self.hash
  local h = hash[hid]
  if not h then return end
  local no = h.no
  local s = self.list[no]
  if s then
    s.count = s.count - 1
  end
  self.usable_nos[no] = 1
  print('free================================', s and s.no, s and s.count)
  hash[hid] = nil
  if s.count <= 0 and self.count > 1 then
     skynet.timeout(10000, function()
       self:safe_del(s.no)
     end)
  end
end

-- Add the service usable from no.
-- @param number no The no.
-- @param mixed flag Usable flag.
function set_usable(self, no, flag)
  local s = self.list[no]
  if not s then return end
  self.usable_nos[no] = flag and 1 or nil
end
