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
local cluster = require 'skynet.cluster'

local print = print
local ipairs = ipairs
local tonumber = tonumber

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

-- Get db query proxy.
function db_proxy(self)
  if not self.db_mgr then
    self.db_mgr = skynet.queryservice('db_mgr')
  end
  return skynet.call(self.db_mgr, 'lua', 'proxy', self.db)
end

-- Get db query proxy list.
function db_proxy_list(self)
  if not self.db_mgr then
    self.db_mgr = skynet.queryservice('db_mgr')
  end
  return skynet.call(self.db_mgr, 'lua', 'proxy_list', self.db)
end

-- Send message to node.
function send(self, node, addr, ...)
  if self.node == node then
    skynet.send(addr, 'lua', ...)
  else
    cluster.send(node, addr, ...)
  end
end

-- Call message from node.
function call(self, node, addr, ...)
  if self.node == node then
    return skynet.call(addr, 'lua', ...)
  else
    return cluster.call(node, addr, ...)
  end
end

function send_map(self, node, addr, ...)
  -- print('send_map', self, node, addr, ...)
  self:send(node, addr, 'handle', ...)
end

function call_map(self, node, addr, ...)
  return self:call(node, addr, 'handle', ...)
end

-- Get db query unique proxy.
-- @param string name
function db_proxy_unique(self, name)
  if not self.db_mgr then
    self.db_mgr = skynet.queryservice('db_mgr')
  end
  return skynet.call(self.db_mgr, 'lua', 'proxy_unique', self.db, name)
end

-- Other.
-------------------------------------------------------------------------------

skynet.init(function()
  time_zone = util.time_zone()
  local server_type = setting.get('type')
  app_id = setting.get('app_id')
  is_world = 'world' == server_type
  is_cross = 'cross' == server_type
  id = tonumber(skynet.getenv('svr_id'))
  name = setting.get('server_name')
  local cluster = setting.get('cluster')
  if cluster then
    node = cluster.name
  end
  
  local dbs = setting.get('db') or {}
  for k, v in ipairs(dbs) do
    if v.name ~= 'DB_LOG' then
      db = v.name
      break
    end
  end

  -- log:dump(_M, 'the _M')
end)

return _M
