--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id pcl.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/12 11:45
 - @uses The PCL class.
--]]

local skynet = require 'skynet'
local json = require 'rapidjson'
local md5 = require 'md5'
local httpc = require 'http.httpc'
local log = require 'log'
local lpeg = require 'lpeg'

local format = string.format
local pcall = pcall
local string = string
local print = print

-- Data.
-------------------------------------------------------------------------------

local cfg
local sid = tonumber(skynet.getenv('svr_id'))
local post_index = 1
local url_cache = url_cache or {}

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == "function" then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

httpc.dns()

-- Local functions.
-------------------------------------------------------------------------------

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

local function get_uri(url)
  local protocol = get_protocol(url)
  local HTTP = lpeg.P(protocol) ^-1
  local HOST = lpeg.C(lpeg.R('AZ', 'az', '09', '..', '::') ^ 1)
  local DIR = lpeg.C(lpeg.P('/') ^0 * lpeg.P(1) ^0)
  local URL = HTTP * HOST * DIR
  local host, uri = URL:match(url)
  --[[
  if uri then
    if string.byte(uri, #uri) == string.byte('/') then
      uri = string.sub(uri, 1, #uri - 1)
    end
  end
  --]]
  return protocol .. host, uri
end

-- Post a uri to normal platform.
-- @param string uri
-- @param table recv_header
-- @param table recv_body
local function post_normal(uri, recv_header, recv_body)
  post_index = post_index + 1
  local header = {
    ['Content-Type'] = format('application/json{"game_id:%d"}', cfg.game_id)
  }
  local host = url_cache.normal.host
  local uri = url_cache.normal.uri .. uri
  log:info('%d POST %s[%s] %s', post_index, host, uri, recv_body)
  local ok, code, body = pcall(
    httpc.request, 'POST', host, uri, recv_header, header, recv_body)
  if not ok then
    code, body = nil, code
  end
  log:info('%d RECV %s %s', post_index, code, body)
  return code, body
end

-- Post a uri to chat platform.
-- @param string uri
-- @param table recv_header
-- @param table recv_body
local function post_chat(uri, recv_header, recv_body)
  local header = {
    ['Content-Type'] = format('application/json{"game_id:%d"}', cfg.game_id)
  }
  local host = url_cache.chat.host
  local uri = url_cache.chat.uri .. uri
  log:info('Chat POST %s[%s] %s', host, uri, recv_body)
  local ok, code, body = pcall(
    httpc.request, 'POST', host, uri, recv_header, header, recv_body)
  if not ok then
    code, body = nil, code
  end
  return code, body
end

-- API.
-------------------------------------------------------------------------------

-- Request uri by post.
-- @param string uri
-- @param table data
-- @param mixed is_chat
function post(uri, data, is_chat)
  data.game_id = cfg.game_id
  data.server_id = data.server_id or sid
  if is_chat then
    data.sign = cfg.game_key
  end
  local msg = json.encode(data)
  local sign_msg = md5.sumhexa(msg .. cfg.game_key) .. msg
  local recv_header = {}
  local code, body
  if is_chat then
    code, body = post_chat(uri, recv_header, sign_msg)
  else
    code, body = post_normal(uri, recv_header, sign_msg)
  end
  if 200 == code then
    return json.decode(body)
  else
    return {code = -1, err = (code and 'code ' .. code or body)}
  end
end

-- Check pay sign is valid.
-- @param table msg
-- @param string sign
-- @return [bool, string]
function check_pay_sign(msg, sign)

end

-- Init.
-- @param table cfg The platform setting config.
-- @param mixed timeout The request timeout(sec).
function init(c, timeout)
  cfg = c
  httpc.timeout = (timeout or 3) * 100
  -- Generate cache.
  local host, uri
  host, uri = get_uri(cfg.host)
  print('uri11111111111111111111', uri)
  url_cache.normal = {host = host, uri = uri or ''}
  host, uri = get_uri(cfg.chat_host)
  print('uri11111111111111111111', uri)
  url_cache.chat = {host = host, uri = uri or ''}
end
