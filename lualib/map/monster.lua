--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id monster.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/11/23 13:45
 - @uses The scene monster object.
--]]

local skynet = require 'skynet'
local client = require 'client'
local object = require 'map.object'
local cfg = require 'cfg'
local util = require 'util'

local e_object_type = require 'enum.object_type'

local type = type
local pairs = pairs
local setmetatable = setmetatable
local print = print

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
  t.tp = e_object_type.monster
  t.id = util.uniq_id() -- Generate id.
  return setmetatable(t, { __index = _M })
end

function init(self, args)
  object.init(self, args)
  local attr_cfg = cfg.get('attr')
  local mcfg = args.cfg
  print('mcfg========================222', args.cfg)
  local data = {}
  for _, one in pairs(attr_cfg) do
    local name = one.name
    if mcfg[name] then
      data[name] = mcfg[name]
    end
  end
  -- Attr init.
  local attr_args = { data = data }
  self.attr:init(attr_args)
end

function pack_appear(self)
  local name, msg = object.pack_appear(self)

  return name, msg
end

function update(self)
  print('update self add:', self.id)
end
