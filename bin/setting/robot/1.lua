--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id 1.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/10 19:33
 - @uses The robot 1 setting file.
--]]
local sid = 1

return {
  login = {
    ip = '127.0.0.1',
    port = 2666,
  },
  world = {
    ip = '127.0.0.1',
    port = 3000 + sid,
  },
  log_flag = 1,
  log_level = 5,
  sid = sid,
  account_prefix = 'dc',
  uid_prefix = 100,
}
