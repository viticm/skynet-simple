--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id auth_tool.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/08/03 17:20
 - @uses The login auth functions tool.
--]]

local md5 = require 'md5'

local _M = {
  auth_key = '123456',
}

-- Check the token is invalid.
-- @param table token_info The token info.
-- @param string token The check token.
-- @param number time The check time.
function _M.check(token_info, token, time)
  local check_token = md5.sumhexa(token_info.token .. time)
  -- print('token_info.token', token, time, token_info.token, check_token)
  return check_token == token
end

return _M
