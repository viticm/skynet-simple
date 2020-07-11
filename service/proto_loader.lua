--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id proto_loader.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/07/10 10:59
 - @uses The proto files loader service.
--]]

local skynet = require "skynet"
local sprotoloader = require "sprotoloader"
local sprotoparser = require "sprotoparser"

local data = {}

local _M = {}

-- Load one proto file.
-- @param string name The proto filename.
-- @return table
local function load(name)
  local filename = string.format('proto/%s.sproto', name)
  local fp = assert(io.open(filename), 'can\'t open file: ' .. name)
  local t = fp:read 'a'
  fp:close()
  return sprotoparser.parse(t, name)
end

function _M.load(t)
  for i, name in ipairs(t) do
    local p = load(name)
    skynet.error('load proto ' ..  name .. " in slot: " .. i)
    data[name] = i
    sprotoloader.save(p, i)
  end
end

function _M.index(name)
  return data[name]
end

return {
  command = _M,
  info = data
}
