--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id attr.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/10/13 14:19
 - @uses The battle attr class.
--]]
local util = require 'util'
local log = require 'log'
local skynet = require 'skynet'
local cfg = require 'cfg'

-- Local defines.
local math = math
local xpcall = xpcall
local pcall = pcall
local print = print
local pairs = pairs
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

id_hash = {}
name_hash = {}

local normal_max <const> = 200
local percent_value <const> = 1000

-- Local functions.
-------------------------------------------------------------------------------

local function gen_hash()
  local conf = cfg.get('attr')
  for id, val in pairs(conf) do
    id_hash[id] = val.name
    name_hash[val.name] = id
    print('gen_hash=================', id, val.name)
  end
end

-- API.
-------------------------------------------------------------------------------

function new(conf)
  local t = {
    _et = conf.et,
    _data = {},                 -- [id] = value
    _hash = {},                 -- [name__p] = value
    _update = {},               -- update attrs.
  }
  return setmetatable(t, { __index = _M })
end

function init(self, args)
  for name, value in pairs(args.data or {}) do
    print('init set==================', name, value)
    self:set(name, value)
  end
  if not args.keep then
    local hpmax = self:get('hpmax')
    print('hpmax======================', hpmax)
    self:set('hp', hpmax)
  end
end

function set(self, name, value)
  self:set_dir(name_hash[name], value)
end

function set_by_id(self, id, value, not_update)
  if id > percent_value then
    self:set_percent(id, value, not_update)
  else
    self:set_fix(id, value, not_update)
  end
  --[[
  local nid = id
  if id > percent_value then
    nid = id % percent_value
  end
  local name = id_hash[nid]
  local fname = name .. '__f'
  local pname = name .. '__p'
  if id < percent_value then
    self._hash[fname] = value
  else
    self._hash[pname] = value
  end
  local final = self._hash[fname] + math.ceil((1000 + self._hash[pname]) / 1000)
  self._data[id] = final
  if not not_update then
    self._update[nid] = 1
  end
  --]]
end

function set_fix(self, id, value, not_update)
  local name = id_hash[id]
  local fname = name .. '__f'
  local pname = name .. '__p'
  self._hash[fname] = value
  local fvalue = self._hash[fname] or 0
  local pvalue = self._hash[pname] or 0
  local final = fvalue * math.ceil((1000 + pvalue / 1000))
  self._data[id] = final
  if not not_update then
    self._update[id] = 1
  end
end

function set_percent(self, id, value, not_update)
  local nid = id % percent_value
  local name = id_hash[nid]
  local fname = name .. '__f'
  local pname = name .. '__p'
  self._hash[pname] = value
  local fvalue = self._hash[fname] or 0
  local pvalue = self._hash[pname] or 0
  local final = fvalue * math.ceil((1000 + pvalue / 1000))
  self._data[nid] = final
  if not not_update then
    self._update[nid] = 1
  end
end

function set_dir(self, id, value, not_update)
  self._data[id] = value
  if not not_update then
    self._update[id] = 1
  end
end

function get(self, name)
  local id = name_hash[name]
  return self._data[id] or 0
end

function update(self)
  if not next(self._update) then return end
  local self_list = {}
  local round_list = {}
  local conf = cfg.get('attr')
  for id, value in pairs(self._update) do
    local one_cfg = conf[id]
    local tp = one_cfg.sync
    if tp & 1 ~= 0 then
      table.insert(self_list, { id = id, value = value })
    elseif tp & 2 ~= 0 then
      table.insert(round_list, { id = id, value = value })
    end

    if tp & 4 ~= 0 then

    end
  end
  if next(self_list) then
    if self._et.send then
      self._et:send('update_attr', { list = self_list })
    end
  end
  if next(round_list) then
    self._et:send_around('update_attr', { list = round_list })
  end
end

-- Other.
-------------------------------------------------------------------------------

skynet.init(function()
  gen_hash()
end)
