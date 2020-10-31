--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id buff.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/09/27 10:47
 - @uses The battle buff class.
--]]

local util = require 'util'
local log = require 'log'
local cfg = require 'cfg'
local e_skill = require 'enum.skill'

-- Local defines.
local math = math
local xpcall = xpcall
local pcall = pcall
local print = print
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

-- Local functions.
-------------------------------------------------------------------------------

-- Check buff can affect by round mode.
-- @param table data The buff data.
-- @param mixed round Do round times(default 1).
-- @return bool
local function round_can_affect(data, round)
  round = round or 1
  data.affect_time = (data.affect_time or 0) + round
  return data.affect_time % data.interval
end

-- Check buff can affect by arpg mode.
-- @param table data The buff data.
-- @param mixed time Do this tick(current tick).
-- @return bool
local function arpg_can_affect(data, time)
  time = time or util.tick()
  data.affect_time = (data.affect_time or time + data.interval)
  return data.affect_time <= time
end

-- Check buff is end by round mode.
-- @param table data The buff data.
-- @param mixed round Current round times(default affect_time).
-- @return bool
local function round_is_end(data, round)
  round = round or data.affect_time
  return data.end_time <= round
end

-- Check buff is end by arpg mode.
-- @param table data The buff data.
-- @param mixed round Current tick(default current tick).
-- @return bool
local function arpg_is_end(data, time)
  time = time or util.tick()
  return data.end_time <= time
end

-- API.
-------------------------------------------------------------------------------

function new(conf)
  local t = {
    _et = conf.et,
    _list = {},                 -- [id] = data
    _hash = {},                 -- [tp] = data
    _event_hash = {},           -- [event] = data
    _mode = e_skill.mode_arpg,  -- Mode.
  }

  if e_skill.mode_arpg == t._mode then
    t.can_affect = arpg_can_affect
    t.is_end = arpg_is_end
  elseif e_skill.mode_round == t._mode then
    t.can_affect = round_can_affect
    t.is_end = round_is_end
  end

  return setmetatable(t, { __index = _M })
end

function init(self, args)

end

function add(self, id, level, args)

end

function del(self, id)

end

function take_affect(self, conf, data)

end

function update(self)

  local buff_cfg = cfg.get('buff')
  local remove_list = {}
  for id, data in pairs(self._list) do
    local conf = buff_cfg[id]

    -- Check end.
    if not conf or self.is_end(data) then
      table.insert(remove_list, id)
    elseif data.interval and self.can_affect(data) then
      self:take_affect(conf, data)
    end

  end

  -- Remove The list.
  for _, id in ipairs(remove_list) do
    print('remove buff:', id)
  end

end
