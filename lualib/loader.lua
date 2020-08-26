--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id loader.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/07/10 19:30
 - @uses The lua loader diffrent from skynet.
--]]
local args = {}
for word in string.gmatch(..., '%S+') do
  table.insert(args, word)
end

SERVICE_NAME = args[1]

local main, pattern
local mainargs

local err = {}
for pat in string.gmatch(LUA_SERVICE, '([^;]+);*') do
  local filename = string.gsub(pat, '?', SERVICE_NAME)
  local f, msg = loadfile(filename)
  if not f then
    table.insert(err, msg)
  else
    pattern = pat
    local is_user_service = string.find(pat, '/service') and 
      not string.find(pat, '/skynet/service/')
    if is_user_service and SERVICE_NAME ~= 'wgate' and 
      SERVICE_NAME ~= 'world/gate' then
      f, msg = loadfile('./lualib/service_init.lua')
      if not f then
        table.insert(err, msg)
      end
      mainargs = SERVICE_NAME:gsub('/', '.')
    end
    main = f
    break
  end
end

if not main then
  error(table.concat(err, '\n'))
end

LUA_SERVICE = nil
package.path , LUA_PATH = LUA_PATH
package.cpath , LUA_CPATH = LUA_CPATH

local service_path = string.match(pattern, '(.*/)[^/?]+$')

if service_path then
  service_path = string.gsub(service_path, '?', args[1])
  package.path = service_path .. '?.lua;' .. package.path
  SERVICE_PATH = service_path
else
  local p = string.match(pattern, '(.*/).+$')
  SERVICE_PATH = p
  if mainargs then -- Will load service file in this way.
    package.path = SERVICE_PATH .. '?.lua;' .. package.path
  end
end

if LUA_PRELOAD then
  local f = assert(loadfile(LUA_PRELOAD))
  f(table.unpack(args))
  LUA_PRELOAD = nil
end

if mainargs then
  main(mainargs, select(2, table.unpack(args)))
else
  main(select(2, table.unpack(args)))
end
