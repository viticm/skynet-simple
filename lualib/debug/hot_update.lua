--[[
 - SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 - $Id hot_update.lua
 - @link https://github.com/viticm/skynet-simple for the canonical source repository
 - @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 - @license
 - @user viticm( viticm.ti@gmail.com )
 - @date 2020/11/28 15:03
 - @uses The lua file reload module.
         !ref:https://github.com/asqbtcupid/lua_hotupdate
--]]
local lfs = require 'lfs'

local getfenv, setfenv, loadstring

if _VERSION == "Lua 5.3" or _VERSION == 'Lua 5.4' then
  function getfenv(f)
    if type(f) == "function" then
      local name, value = debug.getupvalue(f, 1)
      if name == "_ENV" then
        return value
      else
        return _ENV
      end
    end
  end

  function setfenv(f, Env)
    if type(f) == "function" then
      local name = debug.getupvalue(f, 1)
      if name == "_ENV" then
        debug.setupvalue(f, 1, Env)
      end
    end
  end
  debug = debug or {}
  debug.setfenv = setfenv

  function loadstring( ... )
    return load(...)
  end
end

local _M = {}

function _M.fail_notify(...)
  if _M.notify_func then _M.notify_func(...) end
end

function _M.debug_nofity(...)
  if _M.debug_nofityFunc then _M.debug_nofityFunc(...) end
end

-- get filename
local function getFilename(str)
    local idx = str:match(".+()%.%w+$")
    if(idx) then
        return str:sub(1, idx-1)
    else
        return str
    end
end

--get file postfix
local function getExtension(str)
  return str:match(".+%.(%w+)$")
end

-- get require path
local function getReuirePath(str)
  local _, idx = str:find('//')
  if idx then
    return str:sub(idx + 1, -1):gsub('/', '.')
  else
    return ''
  end
end

local function cacheFiles(rootpath, cache)
  for entry in lfs.dir(rootpath) do
    if entry ~= '.' and entry ~= '..' then
      local path = rootpath .. '/' .. entry
      local attr = lfs.attributes(path)
      --print(path)
      local filename = getFilename(entry)

      if attr.mode ~= 'directory' then
        local requirePath = getReuirePath(rootpath)
        -- print('requirePath======================', requirePath, rootpath)
        local postfix = getExtension(entry)
        if 'lua' == postfix then
          local file = filename
          if requirePath ~= '' then
            file = requirePath .. '.' .. file
          end
          path = path:gsub('//', '/')
          cache[file] = path
          -- print('cache============================', file, path)
        end
      else
        -- print(filename .. '\t' .. attr.mode)
        cacheFiles(path, cache)
      end
    end
  end
end

function _M.init_file_map(rootpaths)
  for _, rootpath in pairs(rootpaths) do
    cacheFiles(rootpath, _M._filemap)
  end
end

function _M.init_fake_table()
  local meta = {}
  _M.Meta = meta
  local function fake_T() return setmetatable({}, meta) end
  local function empty_func() end
  local function pairs() return empty_func end
  local function setmetatable(t, metaT)
    _M._metamap[t] = metaT
    return t
  end
  local function getmetatable(t, metaT)
    return setmetatable({}, t)
  end
  local function require(luapath)
    if not _M._requiremap[luapath] then
      local fake_Table = fake_T()
      _M._requiremap[luapath] = fake_Table
    end
    return _M._requiremap[luapath]
  end
  function meta.__index(t, k)
    if k == "setmetatable" then
      return setmetatable
    elseif k == "pairs" or k == "ipairs" then
      return pairs
    elseif k == "next" then
      return empty_func
    elseif k == "require" then
      return require
    elseif _M.call_origin_functions and _M.call_origin_functions[k] then
      return _G[k]
    else
      local fake_Table = fake_T()
      rawset(t, k, fake_Table)
      return fake_Table
    end
  end
  function meta.__newindex(t, k, v) rawset(t, k, v) end
  function meta.__call() return fake_T(), fake_T(), fake_T() end
  function meta.__add() return meta.__call() end
  function meta.__sub() return meta.__call() end
  function meta.__mul() return meta.__call() end
  function meta.__div() return meta.__call() end
  function meta.__mod() return meta.__call() end
  function meta.__pow() return meta.__call() end
  function meta.__unm() return meta.__call() end
  function meta.__concat() return meta.__call() end
  function meta.__eq() return meta.__call() end
  function meta.__lt() return meta.__call() end
  function meta.__le() return meta.__call() end
  function meta.__len() return meta.__call() end
  return fake_T
end

function _M.init_protection()
  _M._protection = {}
  _M._protection[setmetatable] = true
  _M._protection[pairs] = true
  _M._protection[ipairs] = true
  _M._protection[next] = true
  _M._protection[require] = true
  _M._protection[_M] = true
  _M._protection[_M.Meta] = true
  _M._protection[math] = true
  _M._protection[string] = true
  _M._protection[table] = true
end

function _M.add_reloadfiles()
  package.loaded[_M.update_list_file] = nil
  local FileList = require (_M.update_list_file)
  _M.ALL = false
  _M._MMap = {}
  for _, file in pairs(FileList) do
    if file == "_ALL_" then
      _M.ALL = true
      _M._MMap = _M._filemap
      return
    end

    if not _M._filemap[file] then
      if _M.try_reload_filecount[file] == nil or
        0 == _M.try_reload_filecount[file] then
        _M.init_file_map(_M.rootpath)
        if not _M._filemap[file] then
          _M.fail_notify("Hotupdate can't not find "..file)
          _M.try_reload_filecount[file] = 3
        end
      else
        _M.try_reload_filecount[file] = _M.try_reload_filecount[file] - 1
      end
    end

    if _M._filemap[file] then
      _M._MMap[file] = _M._filemap[file]
    end
  end
end

function _M.ErrorHandle(e)
  _M.fail_notify("Hotupdate Error\n"..tostring(e))
  _M.ErrorHappen = true
end

function _M.loadstring_func(syspath)
  io.input(syspath)
  local str = io.read("*all")
  io.input():close()
  return str
end

function _M.build_newcode(syspath, luapath)
  local newcode = _M.loadstring_func(syspath)
  if _M.ALL and _M.oldcode[syspath] == nil then
    _M.oldcode[syspath] = newcode
    return
  end
  if _M.oldcode[syspath] == newcode then
    print('build_newcode is same======================')
    return false
  end
  _M.debug_nofity(syspath)
  local chunk = "--[["..luapath.."]] "
  chunk = chunk..newcode
  local new_func = loadstring(chunk)
  if not new_func then
      print('build_newcode not function======================')
      _M.fail_notify(syspath.." has syntax error.")
      collectgarbage("collect")
      return false
  else
    _M.fake_ENV = _M.fake_T()
    _M._metamap = {}
    _M._requiremap = {}
    setfenv(new_func, _M.fake_ENV)
    local newobj
    _M.ErrorHappen = false
    xpcall(function () newobj = new_func(luapath) end, _M.ErrorHandle)
    if not _M.ErrorHappen then
      _M.oldcode[syspath] = newcode
      return true, newobj
    else
      print('build_newcode not function======================, error')
      collectgarbage("collect")
      return false
    end
  end
end

function _M.Travel_G()
  local visited = {}
  visited[_M] = true
  local function f(t)
    if (type(t) ~= "function" and type(t) ~= "table")
      or visited[t] or _M._protection[t] then
      return
    end
    visited[t] = true
    if type(t) == "function" then
        for i = 1, math.huge do
        local name, value = debug.getupvalue(t, i)
        if not name then break end
        if type(value) == "function" then
          for _, funcs in ipairs(_M.change_funclist) do
            if value == funcs[1] then
              debug.setupvalue(t, i, funcs[2])
            end
          end
        end
        f(value)
      end
    elseif type(t) == "table" then
      f(debug.getmetatable(t))
      local changeIndexs = nil
      for k,v in pairs(t) do
        f(k); f(v);
        if type(v) == "function" then
          for _, funcs in ipairs(_M.change_funclist) do
            if v == funcs[1] then t[k] = funcs[2] end
          end
        end
        if type(k) == "function" then
          for index, funcs in ipairs(_M.change_funclist) do
            if k == funcs[1] then
              changeIndexs = changeIndexs or {}
              changeIndexs[#changeIndexs+1] = index
            end
          end
        end
      end
      if changeIndexs ~= nil then
        for _, index in ipairs(changeIndexs) do
          local funcs = _M.change_funclist[index]
          t[funcs[2]] = t[funcs[1]]
          t[funcs[1]] = nil
        end
      end
    end
  end

  f(_G)
  local registryTable = debug.getregistry()
  f(registryTable)

  for _, funcs in ipairs(_M.change_funclist) do
    if funcs[3] == "_MDebug" then funcs[4]:_MDebug() end
  end
end

function _M.replace_old(oldobj, newobj, luapath, from, deepth)
  if type(oldobj) == type(newobj) then
    if type(newobj) == "table" then
      _M.update_all_func(oldobj, newobj, luapath, from, "")
    elseif type(newobj) == "function" then
      _M.update_func(oldobj, newobj, luapath, nil, from, "")
    end
  end
end

function _M.reload_code(luapath, syspath)
  local oldobj = package.loaded[luapath]
  print('package.loaded================', oldobj)
  if oldobj ~= nil then
    _M.visited_sig = {}
    _M.change_funclist = {}
    local succ, newobj = _M.build_newcode(syspath, luapath)
    print('succ========================', succ)
    if succ then
      _M.replace_old(oldobj, newobj, luapath, "Main", "")
      print('_requiremap=================', _M._requiremap)
      for path, new in pairs(_M._requiremap) do
        local old = package.loaded[path]
        print('oldobj===========================', old, new)
        _M.replace_old(old, new, path, "Main_require", "")
      end
      setmetatable(_M.fake_ENV, nil)
      _M.update_all_func(_M.ENV, _M.fake_ENV, " ENV ", "Main", "")
      if #_M.change_funclist > 0 then
        _M.Travel_G()
      end
      collectgarbage("collect")
    end
  elseif _M.oldcode[syspath] == nil then
    _M.oldcode[syspath] = _M.loadstring_func(syspath)
  end
end

function _M.reset_ENV(obj, _name, from, deepth)
  local visited = {}
  local function f(object, name)
    if not object or visited[object] then return end
    visited[object] = true
    if type(object) == "function" then
      _M.debug_nofity(deepth.."_M.reset_ENV", name, "  from:"..from)
      xpcall(function () setfenv(object, _M.ENV) end, _M.fail_notify)
    elseif type(object) == "table" then
      _M.debug_nofity(deepth.."_M.reset_ENV", name, "  from:"..from)
      for k, v in pairs(object) do
        f(k, tostring(k).."__key", " _M.reset_ENV ", deepth.."    " )
        f(v, tostring(k), " _M.reset_ENV ", deepth.."    ")
      end
    end
  end
  f(obj, _name)
end

function _M.update_upvalue(old_func, new_func, _name, from, deepth)
  _M.debug_nofity(deepth.."_M.update_upvalue", _name, "  from:"..from)
  local old_upvalue_map = {}
  local old_existname = {}
  for i = 1, math.huge do
    local name, value = debug.getupvalue(old_func, i)
    if not name then break end
    old_upvalue_map[name] = value
    old_existname[name] = true
  end
  for i = 1, math.huge do
    local name, value = debug.getupvalue(new_func, i)
    if not name then break end
    if old_existname[name] then
      local old_value = old_upvalue_map[name]
      if type(old_value) ~= type(value) then
        debug.setupvalue(new_func, i, old_value)
      elseif type(old_value) == "function" then
        _M.update_func(
          old_value, value, name, nil, "_M.update_upvalue", deepth.."    ")
      elseif type(old_value) == "table" then
        _M.update_all_func(
          old_value, value, name, "_M.update_upvalue", deepth.."    ")
        debug.setupvalue(new_func, i, old_value)
      else
        debug.setupvalue(new_func, i, old_value)
      end
    else
      _M.reset_ENV(value, name, "_M.update_upvalue", deepth.."    ")
    end
  end
end

function _M.update_func(oldobj, newobj, func_name, oldtable, from, deepth)
  if _M._protection[oldobj] or _M._protection[newobj] then return end
  if oldobj == newobj then return end
  local signature = tostring(oldobj)..tostring(newobj)
  if _M.visited_sig[signature] then return end
  _M.visited_sig[signature] = true
  _M.debug_nofity(deepth.."_M.update_func "..func_name.."  from:"..from)
  if pcall(debug.setfenv, newobj, getfenv(oldobj)) then
    _M.update_upvalue(
      oldobj, newobj, func_name, "_M.update_func", deepth.."    ")
    _M.change_funclist[#_M.change_funclist + 1] =
      {oldobj, newobj, func_name, oldtable}
  end
end

function _M.update_all_func(oldtable, newtable, name, from, deepth)
  if _M._protection[oldtable] or _M._protection[newtable] then return end
  local is_same = getmetatable(oldtable) == getmetatable(newtable)
  is_same = is_same and oldtable == newtable
  if is_same == true then return end
  local signature = tostring(oldtable)..tostring(newtable)
  if _M.visited_sig[signature] then return end
  _M.visited_sig[signature] = true
  _M.debug_nofity(deepth.."_M.update_all_func "..name.."  from:"..from)
  for elname, element in pairs(newtable) do
    local old_element = oldtable[elname]
    if type(element) == type(old_element) then
      if type(element) == "function" then
        _M.update_func(old_element,
                       element,
                       elname,
                       oldtable,
                       "_M.update_all_func",
                       deepth.."    ")
      elseif type(element) == "table" then
        _M.update_all_func(
          old_element, element, elname, "_M.update_all_func", deepth.."    ")
      end
    elseif old_element == nil and type(element) == "function" then
      if pcall(setfenv, element, _M.ENV) then
        oldtable[elname] = element
      end
    end
  end
  local oldmeta = debug.getmetatable(oldtable)
  local newmeta = _M._metamap[newtable]
  if type(oldmeta) == "table" and type(newmeta) == "table" then
    _M.update_all_func(
      oldmeta, newmeta, name.."'s Meta", "_M.update_all_func", deepth.."    ")
  end
end

function _M.set_fileloader(init_filemap_func, loadstring_func)
  _M.init_file_map = init_filemap_func
  _M.loadstring_func = loadstring_func
end

local function getrootpaths()
  local filePaths = {}
  local split_core = require 'split.c'
  local paths = split_core.split(package.path, ';')
  -- print('filePaths====================', #filePaths)

  for _, path in pairs(paths) do
    local barrier = string.find(path, '?')
    local left = string.sub(path, 1, barrier - 1)
    -- local right = string.sub(path, barrier + 1, -1)
    filePaths[left] = left
    -- print('path==============', barrier, path, left, right)
  end
  return filePaths
end

function _M.init(update_list_file,
                 rootpath,
                 fail_notify,
                 ENV,
                 call_origin_functions)
  rootpath = rootpath or getrootpaths()
  _M.update_list_file = update_list_file or "cfg.reload_list"
  _M._MMap = {}
  _M._filemap = {}
  _M.notify_func = fail_notify
  _M.oldcode = {}
  _M.change_funclist = {}
  _M.visited_sig = {}
  _M.fake_ENV = nil
  _M.ENV = ENV or _G
  _M.lua_path_to_syspath = {}
  _M.rootpath = rootpath
  -- _M._filemap =
  _M.init_file_map(rootpath)
  _M.fake_T = _M.init_fake_table()
  _M.call_origin_functions = call_origin_functions
  _M.init_protection()
  _M.ALL = false
  _M.try_reload_filecount = {}
end

function _M.reload(f)
  if f then
    local init_file = f .. '.init'
    if _M._filemap[f] then
      _M._MMap = {}
      _M._MMap[f] = _M._filemap[f]
    elseif _M._filemap[init_file] then
      _M._MMap = {}
      _M._MMap[init_file] = _M._filemap[init_file]
    else
      return
    end
  else
    _M.add_reloadfiles()
  end
  for luapath, syspath in pairs(_M._MMap) do
    if package.loaded[luapath] then
      print('reload==========================', luapath, syspath)
      _M.reload_code(luapath, syspath)
    end
  end
end

return _M
