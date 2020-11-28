--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id service_provider.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/07/11 09:37
 - @uses The service provider.
--]]

local skynet = require 'skynet'
-- local skynetdebug = require 'skynet.debug'
local trace = require 'trace.c'

local traceback = trace.traceback

--[[
skynetdebug.reg_debugcmd('RELOAD', function(f)
  local _LOADED = debug.getregistry()._LOADED
  if _LOADED[f] then

  else
    return skynet.retpack(nil)
  end
  print('reload========================', f)
  if package.loaded[f] then
  print('reload========================1', f)
    package.loaded[f] = nil
    require(f)
  end
  return skynet.retpack(true)
end)
--]]



skynet.register_protocol {
  name = 'master',
  id = 110,
  pack = skynet.pack,
  unpack = skynet.unpack
}

local _M = { stop = false }

local function add_stop_cmd(funcs, release)
  assert(not funcs.stop, 'use release replace stop')
  assert(not funcs.reloadscript, 'reloadscript is system command')
  funcs.stop = function()
    if release then
      release()
    end
    skynet.response()(true)
    skynet.exit()
  end
end

local function dispatch_default(funcs)
  return function (session, source, cmd, ...)
    local f = funcs[cmd]
    if f then
      if session > 0 then
        skynet.retpack(f(...))
      else
        local ok, r = xpcall(f, traceback, ...)
        if not ok then
          print('raise error:', r)
        end
      end
    else
      print(debug.traceback(''))
      if session > 0 then
        skynet.response()(false)
      end
    end
  end
end

function _M.init(mod, arg1, arg2, arg3, arg4)

  if mod.info then
    if 'function' == type(mod.info) then
      skynet.info_func(mod.info)
    else
      skynet.info_func(function()
        return mod.info
      end)
    end
  end
  
  local funcs = mod.command
  local _ = funcs and add_stop_cmd(funcs, mod.release)
  local dispatch = mod.dispatch or {}
  if not dispatch.lua then
    skynet.dispatch('lua', dispatch_default(funcs))
  end
  if not dispatch.master then
    skynet.dispatch('master', dispatch_default(mod.master))
  end
  for name, call in pairs(dispatch) do
    skynet.dispatch(name, call)
  end
  skynet.start(function()
    if mod.init then
      mod.init(arg1, arg2, arg3, arg4)
    end
    if mod.quit then -- quit register.

    end
  end)
end

return _M
