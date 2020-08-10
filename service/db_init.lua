--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id db_init.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/05 17:13
 - @uses The database init service.
--]]

local skynet = require 'skynet'
local service_provider = require 'service_provider'
local mysql = require 'skynet.db.mysql'
local setting = require 'setting'
local mysql_auto = require 'mysql.mysql_auto'
local util = require 'util'
local log = require 'log'

-- Data.
-------------------------------------------------------------------------------

local _M = { cfg = {}, dbs = {} }
local create_sql = [[
create database if not exists `%s` /*!40100 default charset utf8 */
]]

-- Local functions.
-------------------------------------------------------------------------------

local function on_connect(self)
  self:query('set names utf8')
end

local function init()
  _M.cfg = setting.get('db')
  local dbs = _M.dbs
  for index, opt in ipairs(_M.cfg) do
    local name = opt.name
    dbs[name] = dbs[name] or {}
    table.insert(dbs[name], name)
    table.insert(dbs[name], index)
    local one = util.clone(opt)
    one.on_connect = on_connect
    one.database = 'mysql'
    log:dump(one, "the opt=======================")
    local conn = mysql.connect(one)
    print('sql:', string.format(create_sql, opt.database))
    local d = conn:query(string.format(create_sql, opt.database))
    log:dump(d, 'test===============================')
    conn:disconnect()
  end
  for k, v in pairs(dbs) do
    local name = v[1]
    local index = v[2]
    local opt = util.clone(_M.cfg[index])
    opt.on_connect = on_connect
    opt.compare_arrays = false
    local conn = mysql.connect(opt)
    local query = function(...)
      return conn:query(...)
    end
    local ctx = {name = name, query = query, dir = 'dump'}
    mysql_auto.file2db(ctx)
    mysql_auto.db2file(ctx)
    conn:disconnect()
  end
end

function _M.query(name)
  local hash = _M.dbs[name]
  return hash and _M.cfg[hash[2]]
end

return {
  init = init,
  command = _M
}
