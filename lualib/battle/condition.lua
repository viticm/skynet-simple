--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id condition.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/10/12 20:13
 - @uses The battle condition tool.
--]]
local util = require 'util'
local log = require 'log'

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

-- API.
-------------------------------------------------------------------------------

function is_friendly(src, target)

end

function is_emermy(src, target)

end

function is_master(src, target)

end

function is_baby(src, target)

end

function is_teammate(src, target)

end

function is_teammate_baby(src, target)

end
