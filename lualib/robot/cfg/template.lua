--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id template.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/11/16 16:03
 - @uses The robot service config template.
--]]

return {
  -- name: The action name.
  -- param:
  -- timeout: {time(s), next time(s)}
  -- weight: (in random model, default 100)
  {name = 'auto_login', param = {}, timeout = {3}},
	{name = 'discon'},
}
