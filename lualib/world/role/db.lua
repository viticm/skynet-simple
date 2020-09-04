--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id db.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/28 16:14
 - @uses The role db tool.
--]]

local skynet = require 'skynet'
local log = require 'log'
local util = require 'util'
local cluster = require 'skynet.cluster'
local e_error = require 'enum.error'

-- Data.
-------------------------------------------------------------------------------

local select = select
local format = string.format
local table = table
local error = error
local ipairs = ipairs

local build_player_sql <const> = [[
CREATE TABLE `t_player` (
  `uid` bigint(20) unsigned NOT NULL DEFAULT '0',
  `app_id` int(11) DEFAULT NULL,
  `uname` varchar(64) NOT NULL DEFAULT '',
  `createno` int(11) NOT NULL DEFAULT '0',
  `create_time` int(10) unsigned NOT NULL DEFAULT '0',
  `id` varchar(30) NOT NULL,
  `name` varchar(32) NOT NULL,
  `job` tinyint(4) NOT NULL,
  `sex` tinyint(4) DEFAULT NULL,
  `level` int(10) DEFAULT '0',
  `charlook` mediumblob,
  `mapid` int(11) DEFAULT NULL,
  `dup_mapid` int(11) DEFAULT NULL,
  `vip` int(11) DEFAULT NULL,
  `color` int(11) DEFAULT NULL,
  `power` bigint(20) DEFAULT NULL,
  `logout` int(11) DEFAULT NULL,
  `faction_name` varchar(64) DEFAULT NULL,
  `icon` int(11) DEFAULT NULL,
  `model` int(11) DEFAULT NULL,
  `delete_time` int(11) DEFAULT '0',
  `forbid_time` int(11) DEFAULT NULL,
  `platform` int(11) DEFAULT NULL,
  `sdk` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `name_index` (`name`),
  KEY `uid_appid_index` (`uid`,`app_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
]]

local roles_sql <const> = [[
select id, name, job, level
from t_player where user_id = %d
]]

local create_sql <const> = [[
call sp_create_player(%d, %d, "%s", "%s", %d, %d, %d, "%s", "%s")
]]

local create_errors = {
  [1] = e_error.none,
  [2] = e_error.name_exists,
  [3] = e_error.max_limited
}

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

-- Local functions.
-------------------------------------------------------------------------------

-- Query sql.
-- @return table
local function query(proxy, ...)
  local d
  if 1 == select('#', ...) then
    d = skynet.call(proxy, 'lua', 'query', ...)
  else
    d = skynet.call(proxy, 'lua', 'query', format(...))
  end
  if d.errno then
    if 1146 == d.errno then
      query(proxy, build_user_sql)
      return query(proxy, ...)
    else
      error(format('%s[%s]', d.err, table.concat({...})))
    end
  end
  return d
end

-- Update login player.
local function update_login_player(role, way)
  local base = role.base
  local info = {
    name = base.name,
    level = base.level,
    id = role.id,
    uid = role.uid,
    sid = role.sid
  }
  cluster.send('login_' .. role.auth, '.auth_mgr', 'update_player', way, info)
end

-- Update game player.
local function update_game_player(role, way)
  local now = util.now()
  local sql
  if 1 == way then -- Login
    sql = format('update t_player set last = %d', now)
  else -- logout
    local base = role.base
    sql = format('update t_player set logout = %d', now)
  end
  query(role.db_proxy, sql)
end

-- API.
-------------------------------------------------------------------------------

-- Fetch role list by uid.
-- @param number proxy The database proxy
-- @param mixed uid
-- @return table
function fetch_roles(proxy, uid)
  local d = query(proxy, roles_sql, uid)
  local r = {}
  for k, v in ipairs(d) do
    table.insert(r, {
      id = v.player_id,
      name = v.player_name,
      job = v.player_job,
      level = v.player_level,
      forbid = v.forbidtime,
    })
  end
  log:dump(d, 'd========================')
  return r
end

-- Create role.
-- @param number proxy
-- @param table info Create role data.
-- @return number
function create_role(proxy, info)

  local job = info.job
  if job < 1 or job > 3 then
    return e_error.invalid_arg
  end
  local sex = info.sex
  if sex ~= 0 and sex ~= 1 then
    return e_error.invalid_arg
  end
  if util.strlen(info.name) > 10 then
    return e_error.invalid_arg
  end

  local time = util.time()

  local sql = format(create_sql, info.uid, info.sid, 
    info.uname, info.app_id, info.name, info.job, info.sex, time, 
    info.platform or '', info.sdk or info.platform or '')
  log:info('create role: ' .. sql)
  local d = query(proxy, sql)
  local r = d[1][1]
  local err, app_id, rid = table.unpack(r)
  if 1 == err then
    info.create_time = time
    info.app_id = app_id
    info.rid = rid
  end
  return create_errors[err]
end

function update_player(role, way)
  update_login_player(role, way)
  update_game_player(role, way)
end
