--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id db_mgr.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/08 15:38
 - @uses The database manager service.
--]]

local skynet = require 'skynet'
local queue = require 'skynet.queue'
local service_provider = require 'service_provider'
local server = require 'server'
local log = require 'log'

-- Data.
-------------------------------------------------------------------------------

local DB = DB or {}
local INDEX = INDEX or {}
local UNIQUE = UNIQUE or {}

local db_init
local _M = {}

-- Local functions.
-------------------------------------------------------------------------------

local function start(name)
  if DB[name] then return end
  local opt = assert(skynet.call(db_init, 'lua', 'get_opt', name))
  local r = {}
  for i = 1, math.max(opt.count, 1) do
    local addr = skynet.newservice('mysqld', string.format('[%s.d]', name, i))
    assert(skynet.call(addr, 'lua', 'start', opt))
    table.insert(r, addr)
  end
  DB[name] = r
end

local function release()
  for _, v in pairs(DB) do
    for _, addr in ipairs(v) do
      skynet.call(addr, 'lua', 'stop')
    end
  end
  DB = {}
end

local function init()
  LOCK = queue()
  if 'world' == server.tp then

  end
end

-- API.
-------------------------------------------------------------------------------

function _M.proxy(name)
  local list = DB[name]
  if not list then
    LOCK(start, name)
    return _M.proxy(name)
  end
  local index = INDEX[name] or 1
  index = index % (#list)
  if 0 == index then
    index = #list
  end
  return list[index]
end

function _M.proxy_list(name)
  local list = DB[name]
  if not list then
    LOCK(start, name)
    return _M.proxy_list(name)
  end
  return list
end

function _M.proxy_unique(name, flag)
  local str = string.format('%s@%s', name, flag)
  local r = UNIQUE[str]
  if not r then
    r = _M.proxy(name)
    if not UNIQUE[name] then
      UNIQUE[str] = r
    else
      r = UNIQUE[str]
    end
  end
  return r
end

function _M.stat()
  local r = {}
  for name, list in pairs(DB) do
    local count, all_count, finish_count, err_count = 0, 0, 0, 0
    for _, d in ipairs(list) do
      local a, c e = skynet.call(d, 'lua', 'info')
      count, all_count, finish_count, err_count =
        count + 1, all_count + a, finish_count + c, err_count + e
      r[name] = {count, all_count, finish_count, err_count}
    end
  end
  return r
end

skynet.init(function()
  db_init = skynet.uniqueservice('db_init')
end)

return {
  quit = true,
  command = _M,
  info = DB,
  init = init,
  release = release
}
