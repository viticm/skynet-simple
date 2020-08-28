--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id server.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/03 20:06
 - @uses The server tool.
--]]

local skynet = require 'skynet'
local util = require 'util'
local log = require 'log'
local setting = require 'setting'

local print = print
local ipairs = ipairs

-- Data.
-------------------------------------------------------------------------------

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

-- Env variables.
-------------------------------------------------------------------------------
--[[
time_zone   -- The time zone.
type        -- The server type.
id          -- The server id.
name        -- The server name.
node        -- The server node.
channel     -- The server channel.
db          -- The server own db name.
is_world    -- If is world server.
is_cross    -- If is cross server.
--]]

-- API.
-------------------------------------------------------------------------------

-- If self node.
-- @param string node
function is_self(self, node)
  return self.node == node
end

-- Other.
-------------------------------------------------------------------------------

skynet.init(function()
  time_zone = util.time_zone()
  local server_type = setting.get('type')
  is_world = 'world' == server_type
  is_cross = 'cross' == server_type
  name = setting.get('server_name')
  local cluster = setting.get('cluster')
  node = cluster.name
  
  local dbs = setting.get('db')
  for k, v in ipairs(dbs) do
    if v.name ~= 'DB_LOG' then
      db = v.name
      break
    end
  end

  -- log:dump(_M, 'the _M')
end)
