--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id map.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/09/07 19:28
 - @uses The map service.
--]]

local skynet = require 'skynet'
local log = require 'log'
local map = require 'map.init'
local map_handler = require 'map.handler'
local e_error = require 'enum.error'

-- Data.
-------------------------------------------------------------------------------

local _M = {}

local maps = {}               -- [id][line] = object

-- Local functions.
-------------------------------------------------------------------------------

-- Get map object
local function get_map(id, line)
  maps[id] = maps[id] or {}
  return maps[id][line]
end

local function init()

end

-- API.
-------------------------------------------------------------------------------

-- New a map.
-- @param number id Map id.
-- @param number line The map only line.
-- @return bool
function _M.new(id, line)
  local obj = get_map(id, line)
  if obj then
    log:warn('new map [%d:%d] exists', id, line)
    return false
  end
  obj = map.new({ id = id })
  obj:init()
  maps[id][line] = obj
  return true
end

-- Enter.
-- @param number id Map id.
-- @param number line
-- @param table args
-- @return bool
function _M.enter(id, line, args)
  local obj = get_map(id, line)
  if not obj then
    log:warn('enter not find the map object from[%d:%d]', id, line)
    return false
  end
  return obj:enter(args)
end

-- Free.
function _M.free(id, line)
  if not maps[id] then return end
  maps[id][line] = nil
end

-- Handle lua message.
-- @param number id Map id.
-- @param number line Map line.
-- @param string pid Player id.
-- @param table msg
-- @return mixed
function _M.handle(id, line, name, pid, msg)
  print('id====================', id, line, name, pid, msg)
  local obj = get_map(id, line)
  if not obj then
    log:warn('handle[%s] not find the map object from[%d:%d]', name, id, line)
    return { e = e_error.unknown }
  end
  local player
  if pid then
    player = obj.objs[pid]
    if not player then
      log:warn('Handle[%s] not find player from %s', name, pid)
      return { e = e_error.unknown }
    end
  end
  local handler = map_handler[name]
  if not handler then
    log:warn('handle[%s] not find the handler', name)
    return { e = e_error.unknown }
  end

  return handler(map, player, msg)
end

return {
  command = _M,
  init = init,
}
