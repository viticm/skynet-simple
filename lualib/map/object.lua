--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id object.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/09/07 20:24
 - @uses The map object class.
--]]

local skynet = require 'skynet'

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

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

-- API.
-------------------------------------------------------------------------------

function new(conf)
  local t = {
    id = conf.id
  }
  return setmetatable(t, { __index = _M })
end

function init(self)

end

function pack_share(self)

end

function pack_unshare(self)

end
