--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id error.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/27 14:21
 - @uses The error enum.
--]]

return {
  unknown = -1,                           -- Unknown error.
  none = 0,                               -- No error.
  server_full = 1,                        -- Server full.
  version_invalid = 2,                    -- Version invalid.
  auth_failed = 3,                        -- Auth fail.
}
