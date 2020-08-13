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

local sharetable = require 'skynet.sharetable'

-- Data.
-------------------------------------------------------------------------------

local _data = _data or {}
local _rebuild_handler = _rebuild_hander or {}
local _M = {}
package.loaded[...] = _M
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
  _data[name] = sharetable.query(name)
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
    _data[name] = sharetable.query(name)
  end
  return _data[name]
end
