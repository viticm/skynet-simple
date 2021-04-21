--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id init.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/10 20:07
 - @uses The config file.
--]]

local cfg_loader = require 'cfg.loader'
local sharetable = require "skynet.sharetable"

-- Data.
-------------------------------------------------------------------------------

local _data = {}
local _rebuild_handler = {}
local _M = {}
-- package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

-- API.
-------------------------------------------------------------------------------
-- Reload one config.
-- @param string name Config name.
function reload(name)
  if not _data[name] then return end
  _data[name] = cfg_loader.reload(name)
  if _rebuild_handler[name] then
    _rebuild_handler[name](_data[name])
  end
end
-- Register a rebuild config handler.
-- @param string name Config name.
-- @param function handler The rebuild handler(function (t))
function rebuild(name, handler)
  _rebuild_handler[name] = handler
  handler(get(name))
end

-- Reset all cache config addr.
function reset()
  _data = {}
end

-- Get one config.
-- @param string name Config name.
-- @return mixed
function get(name)
  if not _data[name] then
    _data[name] = cfg_loader.get(name)
  end
  return _data[name]
end

-- Get one row config from table.
-- @param string name Config name.
-- @param mixed key The table key.
-- @return mixed
function get_row(name, key)
  local conf = get(name)
  if not conf then return end
  return conf[key]
end

return _M
