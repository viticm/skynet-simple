--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id player.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/09/07 20:28
 - @uses your description
--]]
local skynet = require 'skynet'
local socket = require 'skynet.socket'
local client = require 'client'
local object = require 'map.object'

local e_object_type = require 'enum.object_type'

local tostring = tostring
local type = type
local pairs = pairs
local string = string
local table = table
local load = load
local pcall = pcall
local setmetatable = setmetatable
local print = print
local os = os

-- Data.
-------------------------------------------------------------------------------

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end
setmetatable(_M, { __index = object })

-- API.
-------------------------------------------------------------------------------

function new(conf)
  local t = object.new(conf)
  t.fd = conf.fd
  t.tp = e_object_type.player
  return setmetatable(t, { __index = _M })
end

function init(self, args)
  object.init(self, args)
end

function pack_appear(self)
  local name, msg = object.pack_appear(self)

  return name, msg
end

-- Send a msg to client.
function send(self, name, msg)
  print('player send===================', self.fd, socket.invalid(self.fd))
  if not self.fd then return end
  client.push(self, name, msg)
end

-- Events.
-------------------------------------------------------------------------------

function on_client_loaded(self)
  
end
