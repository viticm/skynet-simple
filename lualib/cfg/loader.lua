--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id loader.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/10 10:40
 - @uses The config file loader tool.
--]]

local log = require 'log'

local tostring = tostring
local type = type
local pairs = pairs
local string = string
local table = table
local load = load
local pcall = pcall
local setmetatable = setmetatable
local print = print

-- Create the module table here
-- Data.
-------------------------------------------------------------------------------

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == "function" then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

_VERSION = "1.20.07.18"

-- Local functions.
-------------------------------------------------------------------------------

local function set_cfg(method, data)
  for _, t in pairs(data) do
    log(' -- Load config %s', t)
    method(t)
  end
end

local function load_list(list)

end
