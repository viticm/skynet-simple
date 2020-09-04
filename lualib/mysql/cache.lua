--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id cache.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/09/04 19:52
 - @uses The mod cache tool.
--]]

local skynet = require 'skynet'
local lock = require 'skynet.queue'
local mysqlaux = require 'skynet.mysqlaux.c'

-- Enviroment.
-------------------------------------------------------------------------------

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

-- Data.
-------------------------------------------------------------------------------

local build_sql <const> = [[
CREATE TABLE IF NOT EXISTS `%s%s` (
  `id` varchar(50) NOT NULL,
  `val` mediumblob NULL,
  `ver` int(11) NULL DEFAULT 0,
  PRIMARY KEY ("id")
) ENGINE=InnoDB DEFAULT CHARSET=utf8
]]

local select_sql <const> = 'select val, ver from %s%s where id = "%s"'
local insert_sql <const> = 'insert ignore %s%s (id, val) values ("%s", "%s")'
local update_sql <const> = 'update %s%s val = "%s", ver = "%s" where id = "%s"'
local check_interval <const> = 1000 -- (base 10ms)

data = data or {} -- All cache table.

-- Local functions.
-------------------------------------------------------------------------------

local function pack(data)
  return mysqlaux.quote_sql_str(skynet.packstring(data))
end

local function unpack(data)
  return skynet.unpack(data)
end

local function query(id, proxy, sql)
  local d = skynet.call(proxy, 'lua', 'query', sql)
  if d.errno then
    skynet.error(format('query error %d %s [%s]', d.errno, d.err, sql))
  end
  return d
end

local function load_record(id, key)
  local d = data[id]
  local proxy = data.proxy
  local prefix = data.prefix

  local d = skynet.call(proxy, 'lua', 'safe_query', 
    format(select_sql, prefix, key, id))
  if d.errno then
    if 1146 == d.errno then
      query(id, proxy, format(build_sql, prefix, key))
      return load_record(id, key)
    else
      skynet.error(d.err)
    end
  elseif 1 == #d then
    d = d[1]
    d[1] = unpack(d[1])
  elseif 0 == #d then
    query(id, proxy, format(insert_sql, prefix, key, id, pack({})))
    return load_record(id, key)
  else
    assert(false)
  end
  return d
end

local function save_record(id, key, val, ver)
  local d = data[id]
  local proxy = d.proxy
  local prefix = d.prefix
  query(id, proxy, format(update_sql, prefix, key, pack(val), ver, id))
end

local function load_one(id, key)
  local d = data[id].save[key]
  if not d then
    data[id].save[key] = load_record(id, key)
    d = data[id].save[key]
  end
  return d
end

local function save_one(id)
  if not data[id].dirty then
    return
  end
  for key, d in pairs(data[id].save) do
    if d.dirty then
      local val, ver = d[1], d[2]
      save_record(id, key, val, ver)
      if d[2] == ver then
        d.dirty = nil
      end
    end
  end
end

-- API.
-------------------------------------------------------------------------------

function init(prefix, id, proxy)
  while data[id] do
    data[id].run = false
    skynet.sleep(10)
  end
  data[id] = {
    id = id,
    prefix = prefix,
    proxy = proxy,
    dirty = true,
    run = true,
    check_time = skynet.now() + check_interval, -- 10's
    queue = setmetatable({}, {__index = function(t, k) 
      local q = lock()
      t[k] = q
      return q
    end}),
    save_lock = lock(),
    save = {}
  }
  skynet.fork(function(id) 
    local d = data[id]
    while d.run do
      if skynet.now() > d.check_time then
        d.check_time = skynet.now() + check_interval
        save(id)
      end
      skynet.sleep(10)
    end
    data[id] = nil
  end, id)
end

function load(id, key, ...)
  local d = data[id].save[key]
  if d then
    return d[1]
  end
  data[id].queue[key](load_one, id, key)
  return data[id].save[key][1]
end

function dirty(id, key)
  data[id].dirty = true
  local d = data[id].save[key]
  d[2] = d[2] + 1
  d.dirty = true
end

function save(id)
  data[id].save_lock(save, id)
end

function unload(id)
  while data[id].dirty do
    save(id)
    local dirty
    for _, d in pairs(data[id].save) do
      if v.dirty then
        dirty = true
        break
      end
    end
    if not dirty then
      data[id].dirty = false
    end
  end
  data[id].run = false
end

function info(dump)
  local c = 0
  for id, d in pairs(data) do
    c = c + 1
    if dump then
      for k in pairs(d.save) do
        skynet.error('%s - %s', id, k)
      end
    end
  end
end
