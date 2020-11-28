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
local battle_util = require 'battle.util'

-- Local defines.
local math = math
local print = print
local next = next
local setmetatable = setmetatable

-- Data.
-------------------------------------------------------------------------------

local c_prepare_error_t <const> = 20

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == 'function' then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

-- local functions.
-------------------------------------------------------------------------------

local function save_param(self, args)
  util.merge(args.from, args.to, { 'dir_cut' })
end

-- Get skill or effect ready time(round mode return round count).
-- @param number time The delay time(ms).
-- @return number
local function get_ready_time(self, time)
  if e_skill.mode_round == self._mode then
    return util.tick() + time
  else
    return math.ceil(time / 1000)
  end
end

-- Handle a skill effects.
-- @param table cfg The skill config.
-- @param mixed args
local function handle_effects(self, cfg, args)
  args = args or {}
  local left_effects = {}
  for index, effect in ipairs(cfg.effects) do
    if effect.delay > 0 then
      table.insert(left_effects, effect)
    else
      self:hit(cfg.id, index, args)
    end
  end
  if next(left_effects) then
    self:add_effects(cfg.id, left_effects, args)
  end
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
  local one_cfg = battle_util.get_skill_cfg(id)
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
  self._effects[id] = self._effects[id] or {}
  for _, effect in ipairs(effects) do
    local ready_t = get_ready_time(effect.delay)
    local cfg = effect.effect
    table.insert(self._effects[id], {ready_t = ready_t, cfg = cfg})
  end
end

-- Delete effects of skill.
-- @param number id Skill ID.
-- @param mixed index Delete effect index(Defalut delete all).
function del_effects(self, id, index)
  if self._effects[id] then
    self._effects[id][index] = nil
  end
end

-- Check use a skill.
-- @param number id Skill ID.
-- @param mixed args
-- @return e
function check(self, id, args)
  if self:is_forbit(id) then return e_error.skill_forbit end
  if self:is_effect_full(id) then return e_error.skill_cannot_spell end
  local conf = battle_util.get_skill_cfg(id)
  if not conf then return e_error.id_invalid end
  local map = self.map
  local target = args.target_id and map:get(args.target_id)

  -- Break.
  if not args.is_trigger then
    local curr_t = util.tick()
    local cur_id = self._prepare.id or self._lead.id
    if id ~= cur_id then
      self:break_spell()
      return e_error.none
    end
    if self:is_prepareing() then
      local x, y = self.x, self.y
      if not self._prepare.target_id and conf.can_move ~= 1 then
        if x ~= self._prepare.x or y ~= self._prepare.y then
          return e_error.invalid_operation
        end
      else
        if self._prepare.target_id ~= args.target_id then
          return e_error.invalid_operation
        end
      end
      if curr_t + c_prepare_error_t < self._prepare.ready_t then
        return e_error.skill_cd_limited
      else
        self:prepare_clear()
        local _args = {
          target_id = self._prepare.target_id,
          level = self._prepare.level,
          x = x,
          y = y
        }
        -- self:hit(id, level, _args)
        handle_effects(id, conf, _args)
      end
    end
  end
  return e_error.none, conf, target
end

-- Get the real skill id.
-- @param number id
-- @return number
function real_id(self, id)
  return id
end

-- Save skill prepare info.
-- @param number id Skill id.
-- @param number level Skill level.
-- @param number delay_t The prepare cost time(ms).
-- @param mixed target_id
-- @param mixed pos
-- @param mixed args
function prepare_save(self, id, level, delay_t, target_id, pos, args)
  args = args or {}
  local d = self._prepare
  local x, y = self.x, self.y
  d.id = id
  d.level = level
  d.ready_t = get_ready_time(self, delay_t)
  d.pos = pos
  d.x, d.y = x, y
  d.is_trigger = args.is_trigger
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
  local origin_id = id
  id = self:real_id(id)
  if id ~= origin_id then
    args.origin = origin_id
  end
  local e, conf, target = self:check(id, args)
  if e ~= e_error.none then return e end

  local pos
  if battle_util.is_valid_pos(args.pos) then
    pos = args.pos
  end

  -- Prepare.
  if conf.prepare > 0 then
    local level = args.level or 1
    local tid = target and target.id
    self:prepare_save(id, level, conf.prepare, tid, pos, args)
  else
    handle_effects(self, conf, args)
  end

  return e
end

-- A skill hit.
-- @param number id Skill ID.
-- @param mixed args
-- @return e
function hit(self, id, args)
  local effects = battle_util.get_effects(id)
  if not effects then
    log:warn('hit can not found the skil config: %d', id)
    return e_error.id_invalid
  end
  local eff_index = args.eff_index
  local eff_cfg = effects[eff_index]
  if not eff_cfg then
    log:warn('hit the index can not found config: %d', eff_index or 0)
    return e_error.invalid_operation
  end

end

-- Update for handle.
-- @param table args
function update(self, args)

  -- Effects.
  if next(self._effects) then
    print('handle effects')
  end

  -- Prepare.

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
