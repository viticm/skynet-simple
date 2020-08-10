--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id init.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/07/13 17:31
 - @uses The setting api table(init like index for include a directory).
--]]

local skynet = require 'skynet'
local datacenter = require 'skynet.datacenter'

local _M = {}

-- initialize data from a table.
-- @param table t
function _M.init(t)
  datacenter.set('SETTING', t)
end

-- Get setting from multi params.
-- @return mixed
function _M.get(...)
  return datacenter.get('SETTING', ...)
end

-- Set value from a key.
-- @param string key
-- @param mixed value
function _M.set(key, value)
  local t = datacenter.get('SETTING')
  if t then
    t[key] = value
    datacenter.set('SETTING', t)
  end
end

-- Set from a table.
-- @param table t
function _M.sets(t)
  local st = datacenter.get('SETTING')
  if st then
    for k, v in pairs(t) do
      st[k] = v
    end
    datacenter.set('SETTING', st)
  end
end

return _M
