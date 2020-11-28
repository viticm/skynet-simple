--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id effect.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/10/13 10:12
 - @uses your description
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

function damage(src, target, cfg)
  local fix = cfg[2]
  print('damage fix:', fix)
  local cost = src.attr:get('attack') - target.attr:get('defend')
  if cost > 0 then
    target:change_hp(-cost, {target = src})
  end
end

function cure(src, target, cfg)

end

function add_buff(src, target, cfg)

end

function del_buff(src, target, cfg)

end

function change_attr(src, target, cfg)

end
