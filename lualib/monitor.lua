--[[
 - Faith ( unkown )
 - $Id monitor.lua
 - @user leafly
 - @date 2021/06/24 14:41
 - @uses 性能监视器
--]]

local log = require 'log'
local skynet = require 'skynet'

-- Local defines.
local setmetatable = setmetatable

-- Data.
-------------------------------------------------------------------------------

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
    setfenv(1, _M) -- Lua 5.1
else
    _ENV = _M -- Lua 5.2+
end

-- Local functions.
-------------------------------------------------------------------------------

-- API.
-------------------------------------------------------------------------------

function new(conf)
    local t = {
        _time = conf.time,      -- log it if the run time more than this(10ms).
        _hash = {},             --[name__s|name__o] = time
    }
    return setmetatable(t, { __index = _M })
end

-- 统计开始
-- @param string name 名称
function start(self, name)
    local hname = name .. '__s'
    if self._hash[hname] then
        log:warn('start the name[%s] has begin', name)
        return
    end
    self._hash[hname] = skynet.now()
end

-- 统计结束
-- @param string name 名称
function stop(self, name)
    local sname = name .. '__s'
    local oname = name .. '__o'
    if not self._hash[sname] or self._hash[oname] then
        log:warn('stop the name[%s] not begin or has stop', name)
        return
    end
    self._hash[oname] = skynet.now()
    local run_time = self._hash[oname] - self._hash[sname]
    if run_time > self._time then
        log:warn('stop the name run time overed[%d,%d]', self.time, run_time)
    end
end
