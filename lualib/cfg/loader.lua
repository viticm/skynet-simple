--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id loader.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/10 10:40
 - @uses The config file loader tool.
--]]

local log = require 'log'
local lfs = require 'lfs'
local cfg_list = require 'cfg.list'
local sharetable = require 'skynet.sharetable'

local tostring = tostring
local type = type
local pairs = pairs
local string = string
local table = table
local load = load
local pcall = pcall
local setmetatable = setmetatable
local print = print
local assert = assert
local next = next

-- Data.
-------------------------------------------------------------------------------

local _M = {}
print('=============================test==================', ...)
-- package.loaded[...] = _M
if setfenv and type(setfenv) == "function" then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

_VERSION = "1.20.07.18"

-- Local functions.
-------------------------------------------------------------------------------

local function set_cfg(method, data)
  for _, t in pairs(data) do
    log('Load config %s', t)
    method(t)
  end
end

local function load_list(list)
  local r = {}
  local function load(root)
    for f in lfs.dir(root) do
      if string.sub(f, 1, 1) ~= '.' then
        local path = root .. '/' .. f
        local attr = lfs.attributes(path)
        if 'directory' == attr.mode then

        else
          local pos = string.find(f, '.lua$')
          if pos then
            local name = string.sub(f, 1, pos - 1)
            print('name=====================', name)
            assert(#name > 0)
            assert(not r[name], string.format('dumplicate filename %s', path))
            if list then
              r[name] = list[name] and path
            else
              r[name] = path
            end
          end
        end
      end
    end -- for
  end
  load('cfg')
  return r
end

local function load_map_obj(list)

end

local function load_map(method, name)

end

local function load_allmap(method, list)

end

-- API.
-------------------------------------------------------------------------------

function loadall(stype)
  local list = cfg_list[stype]
  assert(list, 'unkown server type: ' .. (stype or "unkown"))
  if not next(list) then
    return
  end
  set_cfg(sharetable.loadfile, load_list(list))
  -- Load map

  print('map config', sharetable.query('cfg/map.lua'), '--map')
  print('map config', sharetable.query('test'), '--test')
end

function reload(name)

end

function get(name, raw)
  local filename = name
  if not raw then
    filename = string.format('cfg/%s.lua', name)
  end
  return sharetable.query(filename)
end

return _M
