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

local split_core = require 'split.c'
local extend_core = require 'extend.c'
local uniq = require 'uniq.c'
local skynet = require 'skynet'

local tostring = tostring
local type = type
local pairs = pairs
local string = string
local table = table
local load = load
local pcall = pcall
local setmetatable = setmetatable
local print = print
local os = os
local format = string.format

-- Create the module table here
-- Data.
-------------------------------------------------------------------------------

local _M = {}
package.loaded[...] = _M
if setfenv and type(setfenv) == "function" then
  setfenv(1, _M) -- Lua 5.1
else
  _ENV = _M -- Lua 5.2+
end

_VERSION = "1.20.07.18"

-- Local functions.
-------------------------------------------------------------------------------

local function _func2str(func)
  local info = debug.getinfo(func, 'S')
  return string.format(
    '"%s" -- [[%s:%d]]', func, info.short_src, info.linedefined)
end

-- API.
-------------------------------------------------------------------------------

-- Function to convert a table to a string
-- Metatables not followed
-- Unless key is a number it will be taken and converted to a string
function t2s(t)
  -- local levels = 0
  -- Table to track recursion into nested tables (cL = current recursion level)
  local rL = {cL = 1}
  rL[rL.cL] = {}
  local result = {}
  do
    rL[rL.cL]._f, rL[rL.cL]._s, rL[rL.cL]._var = pairs(t)
    --result[#result + 1] =  "{\n"..string.rep("  ", levels + 1)
    result[#result + 1] = "{"    -- Non pretty version
    rL[rL.cL].t = t
    while true do
      local k, v = rL[rL.cL]._f(rL[rL.cL]._s, rL[rL.cL]._var)
      rL[rL.cL]._var = k
      if k==nil and rL.cL == 1 then
        break
      elseif k==nil then
        -- go up in recursion level
        -- If condition for pretty printing
        -- if result[#result]:sub(-1, -1) == ", " then
          -- remove the tab and the comma
          -- result[#result] = result[#result]:sub(1, -3)
        -- else
          -- just remove the tab
          -- result[#result] = result[#result]:sub(1, -2)
        -- end
        result[#result + 1] = "}, "  -- non pretty version
        -- levels = levels - 1
        rL.cL = rL.cL - 1
        rL[rL.cL + 1] = nil
        --rL[rL.cL].str = rL[rL.cL].str..", \n"..string.rep("  ", levels + 1)
      else
        -- Handle the key and value here
        if type(k) == "number" or type(k) == "boolean" then
          result[#result + 1] = "["..tostring(k).."] = "
        elseif type(k) == "table" then
          result[#result + 1] = "["..t2s(k).."] = "
        else
          local kp = tostring(k)
          if kp:match([["]]) then
            result[#result + 1] = "["..[[']]..kp..[[']].."] = "
          else
            result[#result + 1] = "["..[["]]..kp..[["]].."] = "
          end
        end
        if type(v) == "table" then
          -- Check if this is not a recursive table
          local goDown = true
          for i = 1,  rL.cL do
            if v==rL[i].t then
              -- This is recursive do not go down
              goDown = false
              break
            end
          end
          if goDown then
            -- Go deeper in recursion
            -- levels = levels + 1
            rL.cL = rL.cL + 1
            rL[rL.cL] = {}
            rL[rL.cL]._f, rL[rL.cL]._s, rL[rL.cL]._var = pairs(v)
            --result[#result + 1] = "{\n"..string.rep("  ", levels + 1)
            result[#result + 1] = "{"  -- non pretty version
            rL[rL.cL].t = v
          else
            --result[#result + 1] =
            -- "\""..tostring(v).."\", \n"..string.rep("  ", levels + 1)
            -- non pretty version
            result[#result + 1] = "\""..tostring(v).."\", "
          end
        elseif type(v) == "number" or type(v) == "boolean" then
          --result[#result + 1] =
          -- tostring(v)..", \n"..string.rep("  ", levels + 1)
          result[#result + 1] = tostring(v)..", "  -- non pretty version
        else
          --result[#result + 1] = string.format(
          -- "%q", tostring(v))..", \n"..string.rep("  ", levels + 1)
          -- non pretty version
          result[#result + 1] = string.format("%q", tostring(v))..", "
        end    -- if type(v) == "table" then ends
      end    -- if not rL[rL.cL]._var and rL.cL == 1 then ends
    end    -- while true ends here
  end    -- do ends
  -- If condition for pretty printing
  -- if result[#result]:sub(-1, -1) == ", " then
    -- result[#result] = result[#result]:sub(1, -3) -- remove the tab and the
                                                    -- comma
  -- else
    -- result[#result] = result[#result]:sub(1, -2) -- just remove the tab
  -- end
  result[#result + 1] = "}"  -- non pretty version
  return table.concat(result)
end

-- Function to convert a table to a string with indentation for pretty printing
-- Metatables not followed
-- Unless key is a number it will be taken and converted to a string
function t2spp(t)
  local levels = 0
  -- Table to track recursion into nested tables (cL = current recursion level)
  local rL = {cL = 1}
  rL[rL.cL] = {}
  local result = {}
  do
    rL[rL.cL]._f, rL[rL.cL]._s, rL[rL.cL]._var = pairs(t)
    result[#result + 1] =  "{\n"..string.rep("  ", levels + 1)
    --result[#result + 1] = "{"    -- Non pretty version
    rL[rL.cL].t = t
    while true do
      local k, v = rL[rL.cL]._f(rL[rL.cL]._s, rL[rL.cL]._var)
      rL[rL.cL]._var = k
      if k == nil and rL.cL == 1 then
        break
      elseif k == nil then
        -- go up in recursion level
        -- If condition for pretty printing
        if result[#result]:sub(-1, -1) == ", " then
          result[#result] = result[#result]:sub(1, -3)  -- remove the tab and
                                                        -- the comma
        else
          result[#result] = result[#result]:sub(1, -2)  -- just remove the tab
        end
        --result[#result + 1] = "}, "  -- non pretty version
        levels = levels - 1
        rL.cL = rL.cL - 1
        rL[rL.cL + 1] = nil
        result[#result + 1] = "}, \n"..string.rep("  ", levels + 1) -- for pretty
                                                                  -- printing
      else
        -- Handle the key and value here
        if type(k) == "number" or type(k) == "boolean" then
          result[#result + 1] = "["..tostring(k).."] = "
        elseif type(k) == "table" then
          result[#result + 1] = "["..t2spp(k).."] = "
        else
          local kp = tostring(k)
          if kp:match([["]]) then
            result[#result + 1] = "["..[[']]..kp..[[']].."] = "
          else
            result[#result + 1] = "["..[["]]..kp..[["]].."] = "
          end
        end
        if type(v) == "table" then
          -- Check if this is not a recursive table
          local goDown = true
          for i = 1,  rL.cL do
            if v==rL[i].t then
              -- This is recursive do not go down
              goDown = false
              break
            end
          end
          if goDown then
            -- Go deeper in recursion
            levels = levels + 1
            rL.cL = rL.cL + 1
            rL[rL.cL] = {}
            rL[rL.cL]._f, rL[rL.cL]._s, rL[rL.cL]._var = pairs(v)
            -- For pretty printing
            result[#result + 1] = "{\n"..string.rep("  ", levels + 1)
            --result[#result + 1] = "{"  -- non pretty version
            rL[rL.cL].t = v
          else
            -- For pretty printing
            result[#result + 1] =
              "\""..tostring(v).."\", \n"..string.rep("  ", levels + 1)
            -- non pretty version
            --result[#result + 1] = "\""..tostring(v).."\", "
          end
        elseif type(v) == "number" or type(v) == "boolean" then
          -- For pretty printing
          result[#result + 1] = tostring(v)..", \n"..string.rep("  ", levels + 1)
          --result[#result + 1] = tostring(v)..", "  -- non pretty version
        else
          -- For pretty printing
          result[#result + 1] = string.format("%q",
            tostring(v))..", \n"..string.rep("  ", levels + 1)
          -- non pretty version
          --result[#result + 1] = string.format("%q", tostring(v))..", "
        end    -- if type(v) == "table" then ends
      end    -- if not rL[rL.cL]._var and rL.cL == 1 then ends
    end    -- while true ends here
  end    -- do ends
  -- If condition for pretty printing
  if result[#result]:sub(-1, -1) == ", " then
    result[#result] = result[#result]:sub(1, -3) -- remove the tab and the comma
  else
    result[#result] = result[#result]:sub(1, -2) -- just remove the tab
  end
  result[#result + 1] = "}"
  return table.concat(result)
end

-- Function to convert a table to string following the recursive tables also
-- Metatables are not followed
-- Lua has 8 basic types:
-- 1. nil
-- 2. boolean
-- 3. number
-- 4. string
-- 5. function
-- 6. userdata
-- 7. thread
-- 8. table
-- The table to string and string to table conversion
-- will maintain the following types: nil,  boolean,  number,  string,  table
-- The other three types (function,  userdata and thread)
-- get their tostring values stored and end up as a string ID.
function t2sr(t)
  if type(t) ~= 'table' then return nil, 'Expected table parameter' end
  -- Table to track recursion into nested tables (cL = current recursion level)
  local rL = {cL = 1}
  rL[rL.cL] = {}
  -- Table to store a list of tables
  -- indexed into a string and their variable name
  local tabIndex = {}
  local latestTab = 0
  local result = {}
  do
    -- Start the key value traveral for the table and store the iterator returns
    rL[rL.cL]._f, rL[rL.cL]._s, rL[rL.cL]._var = pairs(t)
    result[#result + 1] = 't0={}' -- t0 would be the main table
    --rL[rL.cL].str = 't0={}'
    rL[rL.cL].t = t -- Table to stringify at this level
    rL[rL.cL].tabIndex = 0
    tabIndex[t] = rL[rL.cL].tabIndex
    while true do
      local key
      -- Get the 1st key and value from the iterator in k, v
      local k, v = rL[rL.cL]._f(rL[rL.cL]._s, rL[rL.cL]._var)
      rL[rL.cL]._var = k
      if k == nil and rL.cL == 1 then
        break  -- All done!
      elseif k == nil then
        -- go up in recursion level
        --rL[rL.cL-1].str = rL[rL.cL-1].str..'\\n'..rL[rL.cL].str
        rL.cL = rL.cL - 1
        if rL[rL.cL].vNotDone then
          -- We were converting a key to string since that was a table.
          -- Now do the same for the value at this level
          key = 't'..rL[rL.cL].tabIndex..'[t'..
            tostring(rL[rL.cL + 1].tabIndex)..']'
          --rL[rL.cL].str = rL[rL.cL].str..'\\n'..key..'='
          result[#result + 1] = "\n"..key.." = "
          v = rL[rL.cL].vNotDone
        end
        rL[rL.cL + 1] = nil
      else
        -- Handle the key and value here
        if type(k) == 'number' or type(k) == 'boolean' then
          key = 't'..rL[rL.cL].tabIndex..'['..tostring(k)..']'
          --rL[rL.cL].str = rL[rL.cL].str..'\\n'..key..'='
          result[#result + 1] = "\n"..key.." = "
        elseif type(k) == 'string' then
          key = 't'..rL[rL.cL].tabIndex..'.'..tostring(k)
          --rL[rL.cL].str = rL[rL.cL].str..'\\n'..key..'='
          result[#result + 1] = "\n"..key.." = "
        elseif type(k) == 'table' then
          -- Table key
          -- Check if the table already exists
          if tabIndex[k] then
            key = 't'..rL[rL.cL].tabIndex..'[t'..tabIndex[k]..']'
            --rL[rL.cL].str = rL[rL.cL].str..'\\n'..key..'='
            result[#result + 1] = "\n"..key.." = "
          else
            -- Go deeper to stringify this table
            latestTab = latestTab + 1
            --rL[rL.cL].str = rL[rL.cL].str..'\\nt'..tostring(latestTab)..'={}'
            result[#result + 1] = "\nt"..tostring(latestTab).."={}"
            rL[rL.cL].vNotDone = v
            rL.cL = rL.cL + 1
            rL[rL.cL] = {}
            rL[rL.cL]._f, rL[rL.cL]._s, rL[rL.cL]._var = pairs(k)
            rL[rL.cL].tabIndex = latestTab
            rL[rL.cL].t = k
            --rL[rL.cL].str = ''
            tabIndex[k] = rL[rL.cL].tabIndex
          end    -- if tabIndex[k] then ends
        else
          -- k is of the type function,  userdata or thread
          key = 't'..rL[rL.cL].tabIndex..'.'..tostring(k)
          --rL[rL.cL].str = rL[rL.cL].str..'\\n'..key..'='
          result[#result + 1] = "\n"..key.." = "
        end    -- if type(k)ends
      end    -- if not k and rL.cL == 1 then ends
      if key then
        rL[rL.cL].vNotDone = nil
        if type(v) == 'table' then
          -- Check if this table is already indexed
          if tabIndex[v] then
            --rL[rL.cL].str = rL[rL.cL].str..'t'..tabIndex[v]
            result[#result + 1] = 't'..tabIndex[v]
          else
            -- Go deeper in recursion
            latestTab = latestTab + 1
            --rL[rL.cL].str = rL[rL.cL].str..'{}'
            --rL[rL.cL].str =
            -- rL[rL.cL].str..'\\nt'..tostring(latestTab)..'='..key
            -- New table
            result[#result + 1] = "{}\nt"..tostring(latestTab)..'='..key
            rL.cL = rL.cL + 1
            rL[rL.cL] = {}
            rL[rL.cL]._f, rL[rL.cL]._s, rL[rL.cL]._var = pairs(v)
            rL[rL.cL].tabIndex = latestTab
            rL[rL.cL].t = v
            --rL[rL.cL].str = ''
            tabIndex[v] = rL[rL.cL].tabIndex
          end
        elseif type(v) == 'number' then
          --rL[rL.cL].str = rL[rL.cL].str..tostring(v)
          result[#result + 1] = tostring(v)
        elseif type(v) == 'boolean' then
          --rL[rL.cL].str = rL[rL.cL].str..tostring(v)
          result[#result + 1] = tostring(v)
        else
          --rL[rL.cL].str = rL[rL.cL].str..string.format('%q', tostring(v))
          result[#result + 1] = string.format('%q', tostring(v))
        end    -- if type(v) == "table" then ends
      end    -- if key then ends
    end    -- while true ends here
  end    -- do ends
  --return rL[rL.cL].str
  return table.concat(result)
end


-- Function to convert a string containing a lua table to a lua table object
function s2t(str)
  local fileFunc
  local safeenv = {}
  if loadstring and setfenv then
    fileFunc = loadstring("t = "..str)
    setfenv(f, safeenv)
  else
    fileFunc = load("t = "..str, "stringToTable", "t", safeenv)
  end
  local err, msg = pcall(fileFunc)
  if not err or not safeenv.t or type(safeenv.t) ~= "table" then
    return nil, msg or type(safeenv.t) ~= "table" and "Not a table"
  end
  return safeenv.t
end

-- Function to convert a string containing a lua recursive
-- table (from t2sr) to a lua table object
function s2tr(str)
  local fileFunc
  local safeenv = {}
  if loadstring and setfenv then
    fileFunc = loadstring(str)
    setfenv(f, safeenv)
  else
    fileFunc = load(str, "stringToTable", "t", safeenv)
  end
  local err, msg = pcall(fileFunc)
  if not err or not safeenv.t0 or type(safeenv.t0) ~= "table" then
    return nil, msg or type(safeenv.t0) ~= "table" and "Not a table"
  end
  return safeenv.t0
end

-- Merge arrays t1 to t2
-- if duplicates flag is false then duplicates are skipped
-- if isduplicate is a given function then that is used to check whether
-- the value of t1 and value of t2 are duplicate using a call like this:
-- isduplicate(t1[i], t2[j])
-- returns table t2
function merge_table(t1, t2, duplicates, isduplicate)
  isduplicate = (is_function(isduplicate) and isduplicate) or function(v1, v2)
    return v1==v2
  end
  for i = 1, #t1 do
    local add = true
    if not duplicates then
      -- Check if this is a duplicate
      for j = 1, #t2 do
        if isduplicate(t1[i], t2[j]) then
          add = false
          break
        end
      end
    end
    if add then
      table.insert(t2,  t1[i])
    end
  end
  return t2
end

-- Function to check whether value v is in array t1
-- if equal is a given function then equal is called with a value from
-- the table and the value to compare.
-- If it returns true then the values are considered equal
function in_array(t1, v, equal)
  equal = (type(equal) == "function" and equal) or function(v1, v2)
    return v1 == v2
  end
  for i = 1, #t1 do
    if equal(t1[i], v) then
      return i    -- Value v found in t1 at ith location
    end
  end
  return false  -- Value v not in t1
end

function empty_table(t)
  for k, v in pairs(t) do
    t[k] = nil
  end
  return true
end

function empty_array(t)
  for i = 1, #t do
    t[i] = nil
  end
  return true
end

local WEAKK = {__mode = "k"}
local WEAKV = {__mode = "v"}

-- Copy table t1 to t2 overwriting any common keys
-- If full is true then copy is recursively going down into nested tables
-- returns t2 and mapping of source to destination and destination to source
-- tables
function copy_table(t1, t2, full, map, tab_done)
  map = map or {
    s2d = setmetatable({}, WEAKK),
    d2s = setmetatable({}, WEAKV)
  }
  -- s2d contains mapping of source table tables to destination tables
  map.s2d[t1] = t2
  -- d2s contains mapping of destination table tables to source tables
  map.d2s[t2] = t1
  tab_done = tab_done or {[t1] = t2}  -- To keep track of recursive tables
  for k, v in pairs(t1) do
    if type(v) == "number" or type(v) == "string" or type(v) == "boolean" or
      type(v) == "function" or type(v) == "thread" or type(v) == "userdata" then
      if type(k) == "table" then
        if full then
          local kp
          if not tab_done[k] then
            kp = {}
            tab_done[k] = kp
            copy_table(k, kp, true, map, tab_done)
            map.d2s[kp] = k
            map.s2d[k] = kp
          else
            kp = tab_done[k]
          end
          t2[kp] = v
        else
          t2[k] = v
        end
      else
        t2[k] = v
      end
    else
      -- type(v) =  = "table"
      if full then
        if type(k) == "table" then
          local kp
          if not tab_done[k] then
            kp = {}
            tab_done[k] = kp
            copy_table(k, kp, true, map, tab_done)
            map.d2s[kp] = k
            map.s2d[k] = kp
          else
            kp = tab_done[k]
          end
          t2[kp] = {}
          if not tab_done[v] then
            tab_done[v] = t2[kp]
            copy_table(v, t2[kp], true, map, tab_done)
            map.d2s[t2[kp]] = v
            map.s2d[v] = t2[kp]
          else
            t2[kp] = tab_done[v]
          end
        else
          t2[k] = {}
          if not tab_done[v] then
            tab_done[v] = t2[k]
            copy_table(v, t2[k], true, map, tab_done)
            map.d2s[t2[k]] = v
            map.s2d[v] = t2[k]
          else
            t2[k] = tab_done[v]
          end
        end
      else
        t2[k] = v
      end
    end
  end
  return t2, map
end

-- Function to compare 2 tables. Returns nil if they are not equal
-- in value or do not have the same recursive link structure
-- Recursive tables are allowed
function compare_tables(t1, t2, traversing)
  if not t2 then
    return false
  end
  traversing = traversing or {}
  traversing[t1] = t2  -- t1 is being traversed to match it to t2
  local donet2 = {}  -- To mark which keys are taken
  for k, v in pairs(t1) do
    --print(k, v)
    if type(v) == "number" or type(v) == "string" or type(v) == "boolean" or
      type(v) == "function" or type(v) == "thread" or type(v) == "userdata" then
      if type(k) == "table" then
        -- Find a matching key
        local found
        for k2, v2 in pairs(t2) do
          if not donet2[k2] and type(k2) == "table" then
            -- Check if k2 is already traversed or is being traversed
            local traversal
            for k3, v3 in pairs(traversing) do
              if v3 == k2 then
                traversal = k3
                break
              end
            end
            if not traversal then
              if compareTables(k, k2, traversing) and v2 == v then
                found = k2
                break
              end
            elseif traversal==k and v2 == v then
              found = k2
              break
            end
          end
        end
        if not found then
          return false
        end
        donet2[found] = true
      else
        if v ~= t2[k] then
          return false
        end
        donet2[k] = true
      end
    else
      -- type(v) == "table"
      --print("-------->Going In "..tostring(v))
      if type(k) == "table" then
        -- Find a matching key
        local found
        for k2, v2 in pairs(t2) do
          if not donet2[k2] and type(k2) == "table" then
            -- Check if k2 is already traversed or is being traversed
            local traversal
            for k3, v3 in pairs(traversing) do
              if v3 == k2 then
                traversal = k3
                break
              end
            end
            if not traversal then
              if compareTables(k, k2, traversing) and v2 == v then
                found = k2
                break
              end
            elseif traversal==k and v2 == v then
              found = k2
              break
            end
          end
        end
        if not found then
          return false
        end
        donet2[found] = true
      else
        -- k is not a table
        if not traversing[v] then
          if not compareTables(v, t2[k], traversing) then
            return false
          end
        else
          -- This is a recursive table so it should match
          if traversing[v] ~= t2[k] then
            return false
          end
        end
        donet2[k] = true
      end
    end
  end
  -- Check if any keys left in t2
  for k, v in pairs(t2) do
    if not donet2[k] then
      return false  -- extra stuff in t2
    end
  end
  traversing[t1] = nil
  return true
end

local setnil = {}  -- Marker table for diff to set nil

-- Function to patch table t with the diff provided to convert it to
-- the next table diff is a structure as returned by the diff_table function
function patch(t, diff)
  local tab_done = {[t]=true}
  for k, v in pairs(diff[t]) do
    if v == setnil then
      t[k] = nil
    else
      t[k] = v
    end
  end
  -- Any other table keys in diff are the child tables
  -- in t so go through them and patch them
  for k, v in pairs(diff) do
    if k ~= t and type(k) == "table" and not tab_done[k] then
      for k1, v1 in pairs(v) do
        if v1 == setnil then
          k[k1] = nil
        else
          k[k1] = v1
        end
      end
    end
  end
  return t
end

-- Function to return the diff patch of t2-t1.
-- The patch when applied to t1 will make it equal in value to t2 such that
-- compareTables will return true
-- Use the patch function the apply the patch
-- map is the table that can provide mapping of any table in
-- t2 to a table in t1 i.e. they can be considered the referring to
-- the same table i.e. that table in t2 after the patch operation
-- would be the same in value as the table in t1 that the map defines
-- but its address will still be the address it was in t2.
-- If there is no mapping for the table found then the same table is looked up
-- at that level to match.
-- But if there is a same table then the diff for that table is obviously 0

-- NOTE: a diff object is temporary and cannot be saved for a later
-- session(This is because of setnil being unique to a session).
-- To save it is better to serialize and save t1 and t2 using t2s functions
function diff_table(t1, t2, map, tab_done, diff)
  map = map or {
      [t2]=t1
    }
  tab_done = tab_done or {[t2] = true}  -- To keep track of recursive tables
  diff = diff or {}
  local diff_dirty
  diff[t1] = diff[t1] or {}
  local keyTabs = {}
  -- To convert t1 to t2 let us iterate over all elements of t2 first
  for k, v in pairs(t2) do
    -- There are 8 types in Lua (except nil and table we check everything here
    if type(v) ~= "table" then      --
      if type(k) == "table" then
        -- Check if there is a mapping else the mapping in t1 is k
        local kt1 = k
        if map[k] then
          kt1 = map[k]
          -- Get diff of kt1 and k
          if not tab_done[k] then
            tab_done[k]= true
            diff_table(kt1, k, map, tab_done, diff)
            diff_dirty = diff_dirty or diff[kt1]
          end
        end
        keyTabs[kt1] = k
        if t1[kt1] == nil or t1[kt1] ~= v then
          diff[t1][kt1] = v
          diff_dirty = true
        end
      else  -- if type(k) == "table" then else
        -- Neither v is a table not k is a table
        if t1[k] ~= v then
          diff[t1][k] = v
          diff_dirty = true
        end
      end    -- if type(k) == "table" then ends
    else  --if type(v) ~= "table" then
      -- v == "table"
      if type(k) == "table" then
        -- Both v and k are tables
        local kt1 = k
        if map[k] then
          kt1 = map[k]
          if not tab_done[k] then
            tab_done[k] = true
            diff_table(kt1, k, map, tab_done, diff)
            diff_dirty = diff_dirty or diff[kt1]
          end
        end
        keyTabs[kt1] = k
        local vt1 = v
        if map[v] then
          vt1 = map[v]
          if not tab_done[v] then
            tab_done[v] = true
            diff_table(vt1, v, map, tab_done, diff)
            diff_dirty = diff_dirty or diff[vt1]
          end
        end
        if t1[kt1] == nil or t1[kt1] ~= vt1 then
          diff[t1][kt1] = vt1
          diff_dirty = true
        end
      else
        local vt1 = v
        if map[v] then
          vt1 = map[v]
          -- Get the diff of vt1 and v
          if not tab_done[v] then
            tab_done[v] = true
            diff_table(vt1, v, map, tab_done, diff)
            diff_dirty = diff_dirty or diff[vt1]
          end
        end
        if t1[k] == nil or t1[k] ~= vt1 then
          diff[t1][k] = vt1
          diff_dirty = true
        end
      end
    end  --if type(v) ~= "table" then ends
  end  -- for k, v in pairs(t2) do ends
  -- Now to find extra stuff in t1 which should be removed
  for k, v in pairs(t1) do
    if type(k) ~= "table" then
      if t2[k] == nil then
        diff[t1][k] = setnil
        diff_dirty = true
      end
    else
      -- k is a table
      -- get the t2 counterpart if it was found
      if not keyTabs[k] then
        diff[t1][k] = setnil
        diff_dirty = true
      end
    end
  end
  if not diff_dirty then diff[t1] = nil end
  return diff_dirty and diff
end

-- Dump a value.
-- @param mixed value the value.
-- @param mixed fold
-- @param mixed flag
-- @return mixed
function dump(value, fold, flag)
  local the_type = type(value)
  if 'table' == the_type then
    local str = t2spp(value)
    return (flag and flag or "") .. str
  elseif 'function' == the_type then
    return _func2str(value)
  else
    return lua_table
  end
end
-- Merge values to table.
-- @param table f From table.
-- @param table t To table.
-- @param table keys Need merge keys of from table.
function merge(f, t, keys)
  if not keys or not next(keys) then return end
  for _, key in ipairs(keys) do
    t[key] = f[key]
  end
end

-- Get now unix time.
function time()
  return os.time()
end

-- Get current tick.
function tick()
  return skynet.now() * 10
end

-- Split string.
function split_row(str, seq)
  return split_core.splitrow(str, seq)
end

-- Split string.
function split(str, seq)
  return split_core.split(str, seq)
end

-- Generate a save sql string.
-- @param string name The table name.
-- @param table data The save table.
-- @param string key Update the column key(default `id`)
-- @param mixed replace_keys Need replace column name list.
-- @param mixed new If insert.
-- @return mixed
function gen_save_sql(name, data, key, replace_keys, new)
  replace_keys = replace_keys or {}
  key = key or 'id'
  local key_value = data[key]
  if not key_value then
    return
  end
  local format_str
  if new then
    format_str = 'insert ignore ' .. name .. ' ('
  else
    format_str = 'update ' .. name ..' set '
  end
  local values = {}
  for k, v in pairs(data) do
    if k ~= key or new then
      local column_name = replace_keys[k] or k
      if 'number' == type(v) then
        format_str = format_str + ' ' + column_name + ' = %d,'
      else
        format_str = format_str + ' ' + column_name + ' = "%s",'
      end
      table.insert(values, v)
    end
  end
  format_str = string.sub(format_str, 1, string.len(format_str) - 1)
  if new then
    format_str = format_str .. ')'
  end
  if not new then
    local where
    if is_number(key_value) then
      where = string.format(' where %s = %d', key, key_value)
    else
      where = string.format(' where %s = "%s"', key, key_value)
    end
    format_str = format_str .. where
  end
  return string.format(format_str, table.unpack(values))
end

function each(obj, iterator)
  if not obj then return end
  for keys, item in pairs(obj) do
    iterator(keys, item)
  end
end

function map(obj, iterator)
  local results = {}
  if not obj then return results end
  each(obj, function(keys, item)
    results[#results + 1] = iterator(keys, item)
  end)
  return results
end

function foldl(obj, iterator, memo)
  if not memo then memo = 0 end
  if not obj then obj = {} end
  each(obj, function(keys, item)
    if memo then
      memo = iterator(memo, keys, item)
    else
      memo = item
    end
  end)
  return memo
end

function foldr(obj, iterator, memo)
  if not obj then obj = {} end
  local reversed = reverse(obj)
  return foldl(reversed, iterator, memo)
end

function find(obj, iterator)
  iterator = iterator or identity
  local result
  if not obj then return result end
  any(reverse(obj), function(keys, item)
    if iterator(keys, item) then
      result = item
      return true
    end
  end)
  return result
end

function filter(obj, iterator)
  local results = {}
  each(obj, function(keys, item)
    if iterator(keys, item) then
      results[#results + 1] = item
    end
  end)
  return results
end

function reject(obj, iterator)
  local results = {}
  each(obj, function(keys, item)
    if iterator(keys, item) == false then
      results[#results + 1] = item
    end
  end)
  return results
end

function all(obj, iterator)
  local result = true
  if not obj then return result end
  each(obj, function(keys, item)
    if result ~= iterator(keys, item) then
      return false
    end
  end)
  return true
end

function any(obj, iterator)
  if not iterator then iterator = identity end
  local result = false
  if not obj then return result end
  each(obj, function(keys, item)
    if not result then
      result = is_true(iterator(keys, item))
    end
  end)
  return result
end

function include(obj, target)
  local found = false
  if obj == nil then return found end
  found = any(obj, function(keys, item)
    return item == target
  end)
  return found
end

function invoke(obj, method, ...)
  return map(obj, function(keys, item)
    if is_function(method) then
      return method(item, arg)
    end
  end)
end

function pluck(obj, key)
  return map(obj, function(keys, item)
    if key == keys then
      return item
    end
  end)
end

function max(obj, memo, iterator)
  if not memo then memo = 0 end
  if not iterator then
    for keys, item in pairs(obj) do
      memo = math.max(item, memo)
    end
  else
    for keys, item in pairs(obj) do
      memo = iterator(item, memo)
    end
  end
  return memo
end

function min(obj, memo, iterator)
  if not memo then memo = 0 end
  if not iterator then
    for keys, item in pairs(obj) do
      memo = math.min(item, memo)
    end
  else
    for keys, item in pairs(obj) do
      memo = iterator(item, memo)
    end
  end
  return memo
end

function shuffle(obj)
  local index = 0
  local shuffled = {}
  each(obj, function(keys, item)
    index = index + 1
    local rand = math.floor(math.random() * index)
    shuffled[index] = shuffled[rand]
    shuffled[rand] = item
  end)
  return shuffled
end

function sort_by(obj, iterator)
  print "TABLE.SORT() ALWAYS RETURN NIL"
end

function group_by(obj, iterator)
  local results = {}
  if is_function(iterator) then
    each(obj, function(keys, item)
      local key = iterator(keys, item)
      if results[key] then
        if is_table(results[key]) then
          table.insert(results[key], item)
        else
          local memo = results[key]
          table.remove(results, results[key])
          local val = {memo, item}
          results[key] = val
        end
      else
        results[key] = item
      end
    end)
  end
  return results
end

function sorted_index(array, obj, iterator)
  if not iterator then iterator = identity end
  local value = iterator(obj)
  local low = 0
  local high = #array
  while low < high do
    local mid = mean(low + high)
    if iterator(array[mid]) < value then
      low = mid + 1
    else
      high = mid
    end
  end
  return low
end

function totable(obj)
  if not obj then return {} end
  if is_table(obj) then
    return obj
  end
  return {obj}
end

function size(obj)
  if is_table(obj) then
    return #obj
  else
    return #keys(obj)
  end
end

function first(array, n)
  if not n then return array[1] end
  local results = map(array, function(keys, item)
    if keys <= n then return item end
  end)
  return results
end

function initial(array, n)
  local len = n or 1
  local actual = 0
  local index = #array - len
  local results = map(array, function(keys, item)
    if actual <= index then
      actual = actual + 1
      return item
    end
  end)
  return results
end

function last(array, n)
  local len = n or 1
  local index = #array - len + 1
  local results = map(array, function(keys, item)
    if keys >= index then return item end
  end)
  return results
end

function rest(array, index)
  local init = index or 1
  local len = init + 1
  local results = map(array, function(keys, item)
    if keys >= len then return item end
  end)
  return results
end

function compact(array)
  return filter(array, function(keys, item)
    if item ~= nil then return item end
  end)
end

function flat(input, output)
  each(input, function(keys, item)
    if is_table(item) then
      flatten(item, output)
    elseif item then
      table.insert(output, item)
    end
  end)
  return output
end

function flatten(array, memo)
  if not memo then memo = {} end
  return flat(array, memo)
end

function without(array)
  print("without")
end

function unique(array, sorted, iterator)
  print("unique")
end

function union()
  print("union")
end

function intersection(array)
  print("intersection")
end

function difference(...)
  local args = arguments(...)
  print(select('#', ...))
  print(arguments)
--  local rest = flatten(slice(arg, 1))
--  return filter(arg[1], function(keys, item)
--    return not include(rest, item)
--  end)
end

function zip()
  print("zip")
end

-- this function has a confusing looking for loop
function zip_object(keys, values)
  local results = {}
  for keys, items in pairs(keys) do
    results[items] = values[keys]
  end
  return results
end

function index_of(array, item)
  print("indexof")
end

function last_index_of(array, item)
  if not array then return -1 end
  local index = #array
  while index > 0 do
    if array[index] == item then
      return index
    end
    index = index - 1
  end
end

function range(start, stop, step)
  local stop = stop or start or 0
  local start = start or 0
  local step = step or 1

  if stop == start then start = 0 end

  local len = math.max(math.ceil((stop - start) / step ), 0)
  local idx = 0
  local ran = {}

  while idx < len do
    idx = idx + 1
    ran[idx] = start
    start = start + step
  end

  return ran
end

function bind(func)
  print("bind")
end

function bind_all(obj)
  print("bindall")
end

function memoize(func, hasher)
  print("memoize")
end

-- FIXME: the delay works but i cant get the func to execute properly
function delay(wait, func)
  local go = os.time() + wait
  repeat
    if os.time == go then
      return func()
    end
  until os.time() > go
end

function defer(func)
  return delay(1, func())
end

-- TODO: this is hard/complicated
function throttle(func, wait)
  print("throttle")
end

function debounce(func, wait, immediate)
  print("debounce")
end

-- FIXME: same problem as delay
function once(func)
  local ran = false
  return function()
    if ran then return end
    ran = true
    return func()
  end
end

function wrap(func, wrapper)
  return function()
    return wrapper(func)
  end
end

-- TODO: finish this
function compose(...)
  local funcs = arg
  return function()
    local args = {}
    for keys, item in pairs(funcs) do
      args = args[key](item)
    end
    return args[0]
  end
end

-- FIXME: wont execute just like delay
function after(times, func)
  if times <= 0 then
    return func()
  end
  return function()
    if times < 1 then
      return func()
    else
      times = times - 1
    end
  end
end

function keys(obj)
  if not is_table(obj) then
    obj = totable(obj)
  end
  local key = {}
  for index, item in pairs(obj) do
    if has(obj, index) then
      key[#key + 1] = index
    end
  end
  return key
end

function values(obj)
  print("values")
end

function functions(obj)
  print("functions")
end

function extend(...)
  local args = initial(arg)
  each(args, function(inkeys, initems)
    for keys, items in pairs(initems) do
      if not args[1][keys] then
        args[1][keys] = items
      end
    end
  end)
  return args[1]
end

function pick(...)
  print("pick")
end

function defaults(...)
  local args = initial(arg)
  each(args, function(inkeys, initems)
    for keys, items in pairs(initems) do
      if args[1][keys] == nil then
        args[1][keys] = initems[keys]
      end
    end
  end)
  return args[1]
end

function clone(obj)
  local r = obj
  if is_table(obj) then
    r = {}
    copy_table(obj, r, true)
  end
  return r
end

-- TODO: test this
function tap(obj, interceptor)
  interceptor(obj)
  return obj
end

-- TODO: finish this
function eq(a, b, stack)
  if a == b then return a ~= 0 or 1 / a == 1 / b end
  if a == nil or b == nil then return a == b end
end

function is_equal(a, b)
  return eq(a, b, {})
end

-- TODO: finish this
function is_empty(obj)
  if obj == nil then return true end
end

function is_table(obj)
  return type(obj) == "table"
end

function is_function(obj)
  return type(obj) == "function"
end

function is_string(obj)
  return type(obj) == "string"
end

function is_number(obj)
  return type(obj) == "number"
end

function is_nil(obj)
  if not obj then
    return true
  else
    return false
  end
end

function is_true(obj)
  if obj then
    return true
  else
    return false
  end
end

function is_boolean(obj)
  return type(obj) == "boolean"
end

function is_userdata(obj)
  return type(obj) == "userdata"
end

function is_thread(obj)
  return type(obj) == "thread"
end

function is_undefined(obj)
  return obj == '' or ""
end

function has(obj, key)
  if not is_table(obj) then return false end
  for keys, item in pairs(obj) do
    if keys == key then
      return true
    else
      return false
    end
  end
end

function identity(value)
  return value
end

function times(n, iterator)
  for keys, items in pairs(range(n)) do
    iterator()
  end
end

function result(object, property)
  if not object then return nil end
  local value = object[property]
  if is_function(value) then
    return value()
  else
    return value
  end
end

function mixin(obj)
  print("mixin")
end

function chain(obj)
  return obj
end

function reverse(obj)
  local length = #obj
  local results = {}
  each(obj, function(keys, item)
    results[length - keys + 1] = item
  end)
  return results
end

function mean(obj, start)
  if not start then start = 0 end
  local value = obj
  if is_number(obj) then
    value = range(start, obj)
  end
  results = foldl(value, function(memo, keys, item)
    if keys % 2 == 0 then
      return memo + item
    else
      return memo - item
    end
  end, start)
  return math.abs(results)
end

function slice(obj, start, stop)
  if not stop then stop = #obj end
  local steps = 0
  if start < 0 then
    start = #obj - math.abs(start)
  end
  if stop < 0 then
    stop = math.abs(stop)
  end
  if start > stop then
    steps = range(stop, start)
  else
    steps = range(start, stop)
  end
  for keys, item in pairs(steps) do
    table.remove(obj, item)
  end
  return obj
end

function arguments(args)
  for i,k in pairs(args) do
    if type(k) == 'table' then
      for key,item in pairs(k) do
        print(item)
      end
    else
      print(k)
    end
  end
end

function time_zone()
  return 1
end

-- Query sql.
-- @return table
function query(proxy, ...)
  local d
  if 1 == select('#', ...) then
    d = skynet.call(proxy, 'lua', 'query', ...)
  else
    d = skynet.call(proxy, 'lua', 'query', format(...))
  end
  if d.errno then
    if 1146 == d.errno then
      -- return query(proxy, ...)
    else
      error(format('%s[%s]', d.err, table.concat({...})))
    end
  end
  return d
end

-- Get string length from utf8(CN word length is one).
-- @return number
function strlen(str)
  local s, len = string.gsub(str, '[\228-\233][\128-\193][\128-\193]*', 'aa')
  return string.len(s)
end

function quote_sql_str(str)
  return extend_core.quote_sql_str(str)
end

function uniq_id()
  return uniq.id(1)
end

-- 包含
function require_ex(module_name)
  local log = require 'log'
  if package.loaded[module_name] then
    log:debug('require_ex module[%s] reload', module_name)
  else
    log:info('require_ex(%s)', module_name)
  end
  package.loaded[module_name] = nil
  return require(module_name)
end

-- 文件加载
function dofile_ex(filename)
  local log = require 'log'
  local func = loadfile(filename..'.lua')
  if nil == func then
    func = loadfile(filename..'.lc')
    if nil == func then
      log:error('dofile_ex(%s) failed', filename)
      os.exit()
      return
    end
  end
  setfenv(func, getfenv(2))
  func()
end

function test()
  print('my test xxxxxxxxxxxxxxx----------')
end
