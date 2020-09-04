--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id role_status.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/09/01 09:40
 - @uses The role status in agent or manager(bit set).
--]]

return {
  none = 0,     -- None
  auth = 1,     -- Account authed.
  create = 2,   -- Create new role.
  online = 4,   -- Online.
  afk = 8,      -- Brief leave(offline).
}
