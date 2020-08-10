--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id mysqld.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/09 21:25
 - @uses The mysqld service.
--]]
local skynet = require 'skynet'
local mysql = require 'skynet.db.mysql'
local util = require 'util'

-- Data.
-------------------------------------------------------------------------------

local name = (...)
local conn
local finsh_count = 0
local all_count = 0
local error_count = 0
local s_opt
local s_ping_t

local _M = {}

-- Local functions.
-------------------------------------------------------------------------------

local function on_connect(self)
	self:query('set names utf8');
end
  
local function release()
	if conn then
		mysql.disconnect(conn)
		conn = nil
	end
	skynet.exit()
end

local function error_check(sql, d)
  if d.errno then
    error(string.format('[(%s)%s]%s', d.errno, d.err, sql))
  end
end

local function check_ping()
  while conn do
    local now = skynet.now()
    local diff = (s_ping_t or 0) - now
    if diff > 0 then
      skynet.sleep(diff)
    else
      s_ping_t = now + (s_opt.check_ping or 10) * 100
      local r, err = pcall(mysql.ping, conn)
      -- print('check_ping.........................', r, err)
      if not r then
        skynet.error(err)
      end
    end
  end
end

local function result(f, sql, d, ...)
  if f then
    f(sql, d)
  end
  return ...
end

local function execute(call, sql, ...)
  s_ping_t = skynet.now() + (s_opt.check_ping or 10) * 100
	all_count = all_count + 1
	local o, d = pcall(call, conn, sql,...)
	finsh_count = finsh_count + 1
	if not o then
		error_count = error_count + 1
		error(string.format('[%s]%s', tostring(d), sql))
	end
	if d.mulitresultset then
		return d, table.unpack(d)
	else
		return d, d
	end
end

-- API.
-------------------------------------------------------------------------------

function _M.query(sql, ...)
  return execute(conn.query, sql, ...)
end

function _M.safe_query(sql, ...)
  return result(error_check, sql, execute(conn.query, sql, ...))
end

function _M.stmt(sql, ...)
  return result(error_check, sql, execute(conn.stmt_query, sql, ...))
end

function _M.start(opt)
  s_opt = opt
	opt.on_connect = on_connect
	conn = mysql.connect(opt)
  --[[
	skynet.fork(function()
		repeat
			conn:query('select 0;')
			skynet.sleep(500)
		until false
	end)
  --]]
  skynet.fork(check_ping)
	return true
end

function _M.info()
	return all_count, finsh_count, error_count
end

return {
	command = _M,
	init = function()
		
	end,
  release = release
}
