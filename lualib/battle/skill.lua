--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id skill.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/09/27 11:01
 - @uses The battle skill class.
--]]

local util = require 'util'
local log = require 'log'
local e_error = require 'enum.error'
local e_skill = require 'enum.skill'
local cfg = require 'cfg.init'

-- Local defines.
local math = math
local xpcall = xpcall
local pcall = pcall
local print = print
local next = next
local setmetatable = setmetatable

-- Data.
-------------------------------------------------------------------------------

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

-- local functions.
-------------------------------------------------------------------------------

local function save_param()

end

-- API.
-------------------------------------------------------------------------------

-- New a skill system object.
-- @param table conf
function new(conf)
  local t = {}
  t._et = conf.et             -- The owner.
  t._effects = {}             -- The effects(waited).
  t._prepare = {}             -- The prepare info(just only skill can prepare).
  t._lead = {}                -- The lead info.
  t._passives = {}            -- The passive skills([class][type] = {list}).
  t._cd_cutdown = {}          -- The cd cut down hash([id] = ms).
  t._forbits = {}             -- The forbit skills([id] = 1).
  t._enable_cd = true         -- If enable cd when use skill.
  t._cd_global = 0            -- Global cd.
  t._mode = e_skill.mode_arpg -- The skill mode.

  return setmetatable(t, { __index = _M })
end

function init(self, args)

end

-- Messages --

-- Send current cd info to client.
function send_cd_info(self)

end

-- Send trigger a passive.
-- @param number id The passive id.
-- @param mixed args
-- @param mixed broadbast If broadbast to nearly.
function send_trigger(self, id, args, broadbast)

end

-- If doing prepare.
-- @return bool
function is_prepareing(self)
  return self._prepare.id and true or false
end

-- If doing lead.
-- @return bool
function is_leading(self)
  return self._lead.id and true or false
end

-- If has prepared.
-- @return bool
function is_prepared(self)
  local curr_t = util.tick()
  return self._prepare.over_t and curr_t <= self._prepare.over_t or false
end

-- A skill if forbit.
function is_forbit(self, id)
  return self._forbits[id] and true or false
end

-- Check is spelling.
function is_spelling(self)
  return self:is_prepareing() or self:is_leading() or next(self._effects)
end

-- Check a skill the effect is full.
-- @param number id
-- @return bool
function is_effect_full(self, id)
  local skill_cfg = cfg.get('skill')
  local one_cfg = skill_cfg[id]
  if not one_cfg then return true end
  local list = self._effects[id]
  if not list then return false end
  local max = 1
  return #list >= max
end

-- Add effect list to skill.
-- @param number id Skill ID.
-- @param table effects Effect list.
-- @param table args
-- @param number over_t Over time.
function add_effects(self, id, effects, args, over_t)

end

-- Delete effects of skill.
-- @param number id Skill ID.
-- @param mixed index Delete effect index(Defalut delete all).
function del_effects(self, id, index)

end

-- Check use a skill.
-- @param number id Skill ID.
-- @param mixed args
-- @return e
function check(self, id, args)
  if self:is_forbit(id) then return e_error.skill_forbit end
  if self:is_effect_full(id) then return e_error.skill_cannot_spell end
end

-- Get the real skill id.
-- @param number id
-- @return number
function real_id(self, id)
  return id
end

function prepare_save(self, id, level, delay_t, target_id, pos, args)

end

function prepare_clear(self)

end

function lead_save(self, id, start_t, target_id, pos, args)

end

function lead_clear(self)

end

-- Break lead.
function lead_break(self)

end

-- Break all spell(include effects).
function break_spell(self)

end

-- Check passives trigger from type.
function check_trigger(self, tp, args)

end

-- Use a skill.
-- @param number id Skill ID.
-- @param mixed args
-- @return e
function use(self, id, args)
  print('skill use====================', id, args)
  local e = self:check(id, args)
  if e ~= e_error.none then return e end
end

-- A skill hit.
-- @param number id Skill ID.
-- @param mixed args
-- @return e
function hit(self, id, args)

end

-- Update for handle.
function update(self)

end

-- Events --

-- On break spell.
function on_break_spell(self)

end

-- Change class event.
-- @param number oclass Old class.
-- @param number nclass New class.
function on_change_class(self, oclass, nclass)

end

-- Change weapon event.
-- @param number otp Old type.
-- @param number ntp New type.
function on_change_weapon(self, otp, ntp)

end
