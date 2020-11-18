--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id init.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/31 19:49
 - @uses The robot action class.
--]]

local skynet = require 'skynet'
local log = require 'log'
local util = require 'util'

-- Data.
-------------------------------------------------------------------------------

local table = table
local print = print
local string = string
local require = require
local assert = assert

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

run_handler = {}
is_end_handler = {}
no_enter_t = {}

-- Local functions.
-------------------------------------------------------------------------------

local function clear(role)
  local d = role.action
  d.index = 1
  d.args = {}
  d.ended = nil
  d.error = nil
  d.start_t = nil
  d.weight_list = nil
end

local function tonext(role)
  local d = role.action
  if d.weight_list then
    local index = 1 --util.rand()
    d.index = index
  else
    d.index = d.index + 1
  end
  d.start_t = nil
  d.args = {}
end

-- Handlers.
-------------------------------------------------------------------------------

-- Action none.
no_enter_t.none = true
function run_handler:none()
  print('none')
end

-- Action none is end handler.
function is_end_handler:none()
  return true
end

-- API.
-------------------------------------------------------------------------------

-- Set a test group for action.
-- @param table role The robot role.
-- @param string name The Test name(Will load the cfg_[name].lua)
function set(role, name)
  clear(role)
  local cfg = require(string.format('robot.cfg.%s', name))
  assert(cfg, 'The robot action config not found: ' .. name)
  local d = role.action
  d.cfg = cfg
  local mod = role.run_mod
  if mod.rand then
    d.weight_list = {}
    for _, v in ipairs(cfg) do
      table.insert(d.weight_list, {v.weight or 100})
    end
  end
end

-- Action run.
-- @param table role
function run(role)
  local mod = role.run_mod
  local name = mod.name
  if mod.once then
    local handler = run_handler[name]
    print('handler==================', handler)
    local _ = handler and handler(role)
    role:close()
    log:debug('Robot action run[%s] once exit', name)
  else
    set(role, name)
    while not role.exit do
      skynet.sleep(20)
      loop(role)
    end
    role:close()
    log:debug('Robot exit: %d', role.pid)
  end
end

-- Run action loop with config.
-- @param table role
function loop(role)

  -- Ping.
  role:ping()

  local d = role.action
  if d.ended or d.error then
    role.exit = true
    return
  end

  -- Config.
  local cfg = d.cfg
  if not cfg or 0 == #cfg then
    d.error = true
    log:error('Robot action can not find the config or empty')
    return
  end
  local one_cfg = cfg[d.index]
  if not one_cfg then
    d.ended = true
    log:debug('Robot all action has run')
    return
  end

  local aname = one_cfg.name
  local acfg = one_cfg.param
  local now = skynet.now()
  local func_is_end = is_end_handler[aname]
  local first_start = false -- The action must be run once.
  if not d.start_t then
    first_start = true
    log:debug('Robot action try to run: %d', d.index)
  end

  -- Check timeout.
  d.start_t = d.start_t or skynet.now()
  if one_cfg.timeout and (now - d.start_t) > (one_cfg.timeout[1] * 100) then
    local timeout_logic = one_cfg.timeout[2]
    if not timeout_logic or 0 == timeout_logic then
      log:error('Robot action timeout: %d', d.index)
      d.error = true
      return
    else
      log:warn('Robot action timeout to next: %d', d.index)
      tonext(role)
      return
    end
  end

  -- Run and check end.
  local args = d.args
  local ended = args.ended or
    (not first_start and func_is_end and func_is_end(role, acfg, args))
  if ended then
    tonext(role)
    log:debug('Robot action do next action: %d', d.index)
    return
  end
  if not no_enter_t[aname] and not role.entered then
    if now - d.start_t < 3000 then
      return
    end
    d.error = true
    log:error('Robot action need enter in game: %s', aname)
    return
  end
  local func_run = run_handler[aname]
  if not func_run then
    d.error = true
    log:error('Robot action can not find the handler: %s', aname)
    return
  end
  func_run(role, acfg, args)
end
