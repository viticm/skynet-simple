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
  invalid_operation = 4,                  -- Invalid operation.
  invalid_arg = 5,                        -- Invalid arg.
  name_exists = 6,                        -- Name exists.
  max_limited = 7,                        -- Max limit.
  name_size = 8,                          -- Name size error.
  enter_fast = 9,                         -- Enter fast.
  enter_repeat = 10,                      -- Enter repeat.
  enter_failed = 11,                      -- Enter failed.
  map_full = 12,                          -- The map is full.
  id_invalid = 13,                        -- ID invalid.
  map_line_invalid = 14,                  -- Map line invalid.
  map_get_failed = 15,                    -- Get map object failed.
}
