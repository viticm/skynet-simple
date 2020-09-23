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
end

local function tonext(role)
  local d = role.action
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
    log:debug('Robot action run[%s] once exit', name)
  else
  end
end
