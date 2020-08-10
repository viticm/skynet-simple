--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id util.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/07/13 17:22
 - @uses The util functions tool for lua.
--]]

local split = require 'split.c'

local _M = {}

local function _func2str(func)
  local info = debug.getinfo(func, 'S')
  return string.format(
    '"%s" -- [[%s:%d]]', func, info.short_src, info.linedefined)
end

local function _table2str(lua_table, raw_table, table_map, n, fold, indent)
  indent = indent or 1
  for k, v in pairs(lua_table) do
    if type(k) == 'string' then
      k = string.format('%q', k)
    else
      k = tostring(k)
    end
    n = n + 1; raw_table[n] = string.rep('  ', indent)
    n = n + 1; raw_table[n] = '['
    n = n + 1; raw_table[n] = k
    n = n + 1; raw_table[n] = ']'
    n = n + 1; raw_table[n] = ' = '
    if type(v) == 'table' then
      if fold and table_map[tostring(v)] then
        n = n + 1; raw_table[n] = tostring(v)
        n = n + 1; raw_table[n] = ',\n'
      else
        table_map[tostring(v)] = true
        n = n + 1; raw_table[n] = '{\n'
        n = _table2str(v, raw_table, table_map, n, fold, indent + 1)
        n = n + 1; raw_table[n] = string.rep('  ', indent)
        n = n + 1; raw_table[n] = '},\n'
      end
    else
      if type(v) == 'string' then
        v = string.format('%q', v)
      elseif 'function' == type(v) then
        v = _func2str(v)
      else
        v = tostring(v)
      end
      n = n + 1; raw_table[n] = v
      n = n + 1; raw_table[n] = ',\n'
    end
  end
  return n
end

-- Dump a value.
-- @param mixed value the value.
-- @param mixed fold
-- @param mixed flag
-- @return mixed
function _M.dump(value, fold, flag)
  local the_type = type(value)
  if 'table' == the_type then
    local raw_table = {}
    local table_map = {}
    table_map[tostring(value)] = true
    local n = 0
    n = n + 1; raw_table[n] = '{\n'
    n = _table2str(value, raw_table, table_map, n, fold)
    n = n + 1; raw_table[n] = '}'
    return (flag and flag or "") .. table.concat(raw_table, '')
  elseif 'function' == the_type then
    return _func2str(value)
  else
    return lua_table
  end
end

-- Get now unix time.
function _M.time()
  return os.time()
end

-- Split string.
function _M.split_row(str, seq)
  return split.split_row(str, seq)
end

-- Generate a save sql string.
-- @param string name The table name.
-- @param table data The save table.
-- @param mixed replace_keys Need replace column name list.
-- @param mixed new If insert.
-- @return string
function _M.gen_save_sql(name, data, replace_keys, new)
  replace_keys = replace_keys or {}
  local format_str
  if new then
    format_str = 'insert ignore ' .. name .. ' ('
  else
    format_str = 'update ' .. name ..' set '
  end
  local values = {}
  for k, v in pairs(data) do
    local column_name = replace_keys[k] or k
    if 'number' == type(v) then
      format_str = format_str + ' ' + column_name + ' = %d,'
    else
      format_str = format_str + ' ' + column + ' = "%s"i,'
    end
    table.insert(values, v)
  end
  format_str = string.sub(format_str, 1, string.len(format_str) - 1)
  if new then
    format_str = format_str .. ')'
  end
  return string.format(format_str, table.unpack(values))
end

return _M
