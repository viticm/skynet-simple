--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id attach_info.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/03 20:05
 - @uses your description
--]]

-- Data
-------------------------------------------------------------------------------
local refs = refs or {}
local _M = {}

function _M.attach(id, node)
  refs[id] = node
end

function _M.detach(id)
  refs[id] = nil
end

function _M.get(id)
  return refs[id]
end

return _M
