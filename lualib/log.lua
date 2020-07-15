--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id log.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/07/13 17:31
 - @uses The log api.
--]]

local skynet = require "skynet"
local logger = require "print.c"
local util = require "util"
local setting = require "setting"

local log = {
  flag = false,
  level = 5
}

local function get_module_info(level)
  local module_info = ""
  local info = debug.getinfo(level, "Sl")
  if info then
    module_info = string.format("%s:%d", info.short_src, info.currentline)
  end
  module_info = module_info .. " -- "
  return module_info
end

function log.format(format_str, ...)
  return string.format(format_str, ...)
end

function log:msg(...)
  local msg
  if 1 == select("#", ...) then
    msg = tostring((...))
  else
    msg = self.format(...)
  end
  if log.flag then
    msg = get_module_info(4) .. msg
  end
  return msg
end

function log:error(...)
  if self.level < 1 then
    return
  end
  local msg = self:msg(...)
  logger.print(1, msg)
end

function log:warn(...)
  if self.level < 2 then
    return
  end
  local msg = self:msg(...)
  logger.print(2, msg)
end

function log:info(...)
  if self.level < 3 then
    return
  end
  local msg = self:msg(...)
  logger.print(3, msg)
end

function log:debug(...)
  if self.level < 4 then
    return
  end
  local msg = self:msg(...)
  logger.print(4, msg)
end

function log:__call(...)
  if self.level < 5 then
    return
  end
  local msg = self:msg(...)
  logger.print(5, msg)
end

function log:dump(value, flag)
  if self.level < 5 then
    return
  end
  local msg = self:msg(util.dump(value, nil, flag))
  logger.print(5, msg)
end

skynet.init(function()
  log.flag = true --1 == setting.get('log_flag') and true or false
  log.level = setting.get('log_level') or 5
  print('log=======', log.flag, log.level)
end)

return setmetatable(log, log)
