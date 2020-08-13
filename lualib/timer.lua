--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id timer.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/05 15:37
 - @uses A simple timer.
--]]

local heap = require 'minheap.c'
local trace = require 'trace.c'
local skynet = require 'skynet'

-- Data.
-------------------------------------------------------------------------------

local HEAP = heap.new()
local cbs = {}
local ids = {}
local ID_GEN = 1
local handler = {}
local MIN_TI = math.huge
local update
local _M = {}

-- Local functions.
-------------------------------------------------------------------------------

local function poll_with_skynet(now)
  local _, min = heap.top(HEAP)
  if min and min < MIN_TI then
    MIN_TI = min
    skynet.timeout(min - now, function() 
      if MIN_TI == min then
        MIN_TI = math.huge
        update()
      end
    end)
  end
end

local function safe_call(id)
  local call = ids[id]
  if call then
    ids[id] = nil
    local ok, err = xpcall(call, trace.traceback)
    if not ok then
      skynet.error(err)
    end
  end
end

function update(min)
  local now = skynet.now()
  repeat
    local id = heap.pop(HEAP, 99999999)
    if not id then
      break
    end
    safe_call(id)
  until false
  poll_with_skynet(now)
end

-- API.
-------------------------------------------------------------------------------

function _M.re_calc_min_timeout()
  MIN_TI = math.huge
  poll_with_skynet(skynet.now())
end

function _M.add(time, cb)
  local now = skynet.now()
  local expire = now + time
  return _M.add_expire(expire, cb)
end

function _M.add_expire(expire, cb)
  local id = ID_GEN
  ID_GEN = ID_GEN + 1
  ids[id] = cb
  heap.add(HEAP, id, expire)
  poll_with_skynet(skynet.now())
  return id
end

function _M.remove(id)
  local cb = ids[id]
  ids[id] = nil
  return cb
end

function _M.add_loop(time, cb)
  local h = _M.add(time, function() 
    cb()
    _M.add_loop(time, cb)
  end)
  handler[cb] = h
  return cb
end

function _M.remove_loop(hd)
  local h = handler[hd]
  if not h then
    return
  end
  _M.remove(h)
  handler[id] = nil
end

skynet.init(function() 
  local debug = require 'skynet.debug'
  debug.reg_debugcmd('on_time_offset_mod', function() 
    skynet.retpack(_M.re_calc_min_timeout())
  end)
end)

return _M
