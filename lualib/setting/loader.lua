--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id loader.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/07/22 15:56
 - @uses The setting loader.
--]]

local skynet = require 'skynet'
local cluster = require 'skynet.cluster'
local json = require 'rapidjson'
local setting = require 'setting'
local httpc = require 'http.httpc'
local md5 = require 'md5'
local log = require 'log'

local _M = {}

-- Reuest a http from get.
-- @param string host The host name.
-- @param string uri The uri.
-- @param string content The content.
local function request(host, uri, content)
  skynet.error('setting request ' .. host .. uri)
  local code, recv = httpc.request('GET', host, uri, {}, {}, content)
  assert(200 == code, recv)
  return json.decode(recv)
end

-- Get the protocol from uri.
-- @param string url The setting url.
-- @return mixed
local function get_protocol(url)
	local protocol = url:match("^[Hh][Tt][Tt][Pp][Ss]?://")
	if protocol then
		protocol = string.lower(protocol)
  end
  return protocol
end

local function getUri()
  local setting_host = skynet.getenv('setting_host')
  local protocol = get_protocol(setting_host)
  local lpeg = require 'lpeg'
  local HTTP = lpeg.P(protocol) ^-1
  local HOST = lpeg.C(lpeg.R('AZ', 'az', '09', '..', '::') ^ 1)
  local DIR = lpeg.C(lpeg.P('/') ^0 * lpeg.P(1) ^0)
  local URL = HTTP * HOST * DIR
  local host, uri = URL:match(setting_host)
  if uri then
    if string.byte(uri, #uri) == string.byte('/') then
      uri = string.sub(uri, 1, #uri - 1)
    end
  end
  return protocol .. host, uri
end

-- Node setting.
-- @param string stype server type
-- @param number sid server id
local function request_node_info(stype, sid)
  local name = string.format('%s_%d', stype, sid)
  local host, uri = getUri()
  local r = request(host, string.format('%s/%s.json', uri, name), '')
  log:dump(r, 'the request=================')
  if r.clusternode and setting.clusternode() ~= s.clusternode then
    cluster.open(r.clusternode)
  end
  return r
end

-- Update the cluster node info.
function _M.refresh_cluster_node()
  local host, uri = getUri()
  local r = request(host, uri .. '/clusternode.json', '')
  return cluster.reload(r)
end

-- Load from platform.
function _M.load_platform(stype, sid)
  
  log:debug('load_platform begin')

  -- _M.refresh_cluster_node()
  local node = request_node_info(stype, sid)
  setting.sets(node)

  -- Other settings.
  if 'login' == stype then

  elseif 'world' == stype then

  elseif 'global' == stype then

  end

  log:debug('load_platform end')
end

return _M
