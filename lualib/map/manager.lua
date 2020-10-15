--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id manager.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/09/07 19:28
 - @uses The map manager tool.
--]]

local skynet = require 'skynet'
local service_pool = require 'service_pool'
local cfg = require 'cfg'
local log = require 'log'
local util = require 'util'
local e_map = require 'enum.map'
local queue = require 'skynet.queue'
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

local line_max <const> = 99                 -- The normal map max line count.
local normal_map_max <const> = 1            -- The normal line map object max.
local other_map_max <const> = 50            -- Other line map object max.

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

-- API.
-------------------------------------------------------------------------------

function init()
  pools = {}            -- [id] = service_pool
  lines = {}            -- [id][line] = { count, no }
  locks = {}
end

-- Get the map config.
-- @param number id Map id.
-- @return mixed
function get_cfg(id)
  local conf = cfg.get('map')
  return conf[id]
end

-- Get map lock.
function get_lock(id)
  if not locks[id] then
    locks[id] = queue()
  end
  return locks[id]
end

-- Create a pool for map.
-- @param number id Map id.
-- @return mixed
function create_pool(id)
  local conf = get_cfg(id)
  if not conf then return end
  local args = { max = line_max, def = 0, boot_arg = id, boot = 'map' }
  if e_map.tp_normal == conf.tp then
    args.cap = normal_map_max
  elseif e_map.tp_stage == conf.tp then
    args.cap = other_map_max
  else
    args.cap = other_map_max
  end
  print('create_pool================', args)
  local pool = service_pool.new(args)
  lines[id] = {}
  return pool
end

-- Get the free map line.
-- @param number id Map id.
-- @param mixed new Need try create new map when not found.
-- @return mixed
function get_map_line(id, new)
  local list = lines[id] or {}
  print('line=================-1', line)
  local conf = get_cfg(id)
  print('get_map===================', id, new)
  local line
  for k, v in pairs(list) do
    if v.count < conf.max_online then
      line = k
      break
    end
  end
  if not line then
    if not new then return end
    line = create(id)
  end
  print('line=================1', line)
  return line
end

-- Get the map service pool.
-- @param number id Map id.
-- @return table
function get_pool(id)
  pools[id] = pools[id] or create_pool(id)
  return pools[id]
end

-- Create a new map object.
-- @param number id Map id.
-- @return mixed
function create(id)
  local pool = get_pool(id)
  if not pool then return end
  local line = util.uniq_id()
  local addr, index, sub = pool:get(line)
  print('create============================', addr, index, sub)
  if not addr then
    return
  end
  local no = (index - 1) * pool.cap + sub
  local info = { count = 0, no = no }
  lines[id][line] = info                 -- initial player count.

  local r = skynet.call(addr, 'lua', 'new', id, line)
  if not r then
    return
  end
  return line
end

-- @param number id Map id.
-- @param mixed line Map line(unique id).
-- @param mixed args.
-- @return e_error, addr?, line?
function enter(id, line, args)
  log:info('enter %d|%s start', id, line)
  local conf = get_cfg(id)
  if not conf then
    log:warn('enter %d|%s failed, not find config', id, line)
    return e_error.invalid_id
  end
  print('line===================', id, line)
  local switch = args.switch
  local info = line and lines[id] and lines[id][line]
  if not info then
    if conf.tp ~= e_map.tp_normal or switch then
      return e_error.map_line_invalid
    end
    local lock = get_lock(id)
    line = lock(get_map_line, id, true)
  end
  print('line===================', line)
  if not line then
    log:warn('enter %d|%s failed, not get map', id, line)
    return e_error.map_get_failed
  end
  local pool = get_pool(id)
  local addr = pool:get(line)
  local r = skynet.call(addr, 'lua', 'enter', id, line, args)
  info = lines[id][line]
  if r then
    info.count = info.count + 1
  end
  log:info('enter %d|%s end', id, line)
  return r, addr, line
end
