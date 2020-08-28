--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id role_mgr.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/21 19:55
 - @uses Role manager.
--]]

local skynet = require 'skynet'

-- Data.
-------------------------------------------------------------------------------

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

hash = hash or {}   -- Role rid hash [rid] = role.
fds = fds or {}     -- Role fd hash [fd] = role.

-- API.
-------------------------------------------------------------------------------

function init()

end

function on_client_msg(fd, msg, sz)

end

function on_lua_msg(session, cmd, fd, ...)

end
