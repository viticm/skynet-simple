--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id mods.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/09/04 17:13
 - @uses The role mods tool.
--]]

-- Enviroment.
-------------------------------------------------------------------------------

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

-- API.
-------------------------------------------------------------------------------

function load(role)

end

function enter(role)

end

function after_enter(role)

end
