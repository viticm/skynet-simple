--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id login_db.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/08 16:22
 - @uses The login database tool.
--]]

local skynet = require 'skynet'

-- Data.
-------------------------------------------------------------------------------

local format = string.format
local proxy

local build_player_sql = [[
create table if not exists `t_player` (
  `rid` varchar(50) not null,
  `rname` varchar(50) not null,
  `icon` int(11) not null,
  `icon_frame` int(11) not null,
  `sid` int(11) not null,
  `last` int(11) not null,
  `level` int(11) not null,
  primary key (`rid`),
  KEY `rname` (`rname`) using hash,
  KEY `uid` (`uid`) using hash,
  KEY `sid` (`sid`) using hash,
) engine=InnoDB default charset=utf8
]]

local build_user_sql = [[
create table if not exists `t_user` (
  `uid` varchar(50) not null,
  `last` int(11) not null,
  primary key (`uid`)
) engine=InnoDB default charset=utf8
]]

-- Local functions.
-------------------------------------------------------------------------------

local function query(...)
  local d
  if 1 == select('#', ...) then
    d = skynet.call(proxy, 'lua', 'query', ...)
  else
    d = skynet.call(proxy, 'lua', 'query', format(...))
  end
  if d.errno then
    if 1146 == d.errno then
      query(proxy, build_user_sql)
      query(proxy, build_player_sql)
      return query(proxy, ...)
    else
      error(format('%s[%s]', d.err, table.concat({...})))
    end
  end
  return d
end

skynet.init(function() 
  local db_mgr = skynet.uniqueservice('db_mgr')
  proxy = assert(skynet.call(db_mgr, 'lua', 'query', 'DB_LOGIN'))
end)

return function(...)
  return query(...)
end
