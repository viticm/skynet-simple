--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id skill.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/10/14 11:06
 - @uses Skill enum.
--]]

return {
  mode_arpg = 1,                          -- The skill arpg mode.
  mode_round = 2,                         -- The skill round mode.

  shape_rect = 1,
  shape_cricle = 2,
  shape_sector = 3,
  shape_ring = 4,

  buff = {                                -- Buff type.
    tp_hash_class = 1,                    -- The type class hash.

    event_hash_death = 1,                 -- The death event hash.
  },

  skill = {                               -- Skill type.

  }
}
