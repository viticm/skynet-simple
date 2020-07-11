/**
 * SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 * $Id lua-trace.c
 * @link https://github.com/viticm/skynet-simple for the canonical source repository
 * @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 * @license
 * @user viticm( viticm.ti@gmail.com )
 * @date 2020/07/11 10:38
 * @uses The full traceback for lua.
 */
#include <inttypes.h>
#include <string.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#define NUM_MAX (3)
#define BUF_SIZE_MAX (15 * 1024)

static int32_t 
v2str(lua_State *L, luaL_Buffer *buf, int32_t index, int32_t level);

//Lua table to string.
static int32_t 
t2str(lua_State *L, luaL_Buffer *buf, int32_t index, int32_t level) {
  if (--level < 0) {
    lua_pushfstring(buf->L, "%p(table)", lua_topointer(L, index));
    luaL_addvalue(buf);
  } else {
    int32_t count = 0;
    lua_pushfstring(buf->L, "%p{", lua_topointer(L, index));
    luaL_addvalue(buf);

    luaL_checktype(L, index, LUA_TTABLE);
    lua_pushnil(L);
    while (lua_next(L, index - 1)) {
      v2str(L, buf, -2, level);
      luaL_addstring(buf, "=");
      v2str(L, buf, -1, level);
      luaL_addstring(buf, ",");
      lua_pop(L, 1);
      if (count >= NUM_MAX) {
        luaL_addstring(buf, "...,");
        lua_pop(L, 1);
        break;
      }
    }
    luaL_addstring(buf, "}");
  }
  return 1;
}

//Lua function to string.
static int32_t f2str(lua_State *L, luaL_Buffer *buf, int32_t index) {
  luaL_checktype(L, index, LUA_TFUNCTION);
  if (lua_iscfunction(L, index)) {
    lua_pushfstring(buf->L, "%p(cfunc)", lua_topointer(L, index));
  } else {
    lua_Debug ar;
    lua_pushvalue(L, index);
    lua_getinfo(L, ">Sln", &ar);
    lua_pushfstring(buf->L,
                    "%p(lfunc@%s:%d)",
                    lua_topointer(L, index),
                    ar.short_src,
                    ar.linedefined);
  }
  return 1;
}

//All lua value to string.
static int32_t
v2str(lua_State *L, luaL_Buffer *buf, int32_t index, int32_t level) {
  int32_t type = lua_type(L, index);
  const char *typename = lua_typename(L, type);
  switch (type) {
    case LUA_TSTRING:
      {
        lua_pushfstring(buf->L, "%s(%s)", lua_tostring(L, index), typename);
        luaL_addvalue(buf);
      }
      break;
    case LUA_TNUMBER:
      {
        lua_pushfstring(buf->L, "%f(%s)", lua_tonumber(L, index), typename);
        luaL_addvalue(buf);
      }
      break;
    case LUA_TTABLE:
      {
        t2str(L, buf, index, level);
      }
      break;
    case LUA_TFUNCTION:
      {
        f2str(L, buf, index);
      }
      break;
    case LUA_TTHREAD:
    case LUA_TUSERDATA:
    case LUA_TLIGHTUSERDATA:
      {
        lua_pushfstring(buf->L, "%p(%s)", lua_topointer(L, index), typename);
      }
      break;
    case LUA_TBOOLEAN:
      {
        lua_pushfstring(buf->L, "%s(%s)",
                        lua_toboolean(L, index) ? "true" : "false",
                        typename);
      }
      break;
    case LUA_TNIL:
      {
        luaL_addstring(buf, "nil");
      }
      break;
    default:
      break;
  }
  return 0;
}

int32_t traceback(lua_State *L) {
  lua_Debug ar;
  int32_t level = 1;
  int32_t index = 0;
  const char *msg = NULL;

  luaL_Buffer buf;
  luaL_buffinit(L, &buf);

  luaL_addstring(&buf, "\n------------------------------------------------\n");
  msg = lua_tostring(L, 1);
  msg = msg ? msg : "unkonw";
  luaL_addstring(&buf, "error: ");
  luaL_addstring(&buf, msg);
  luaL_addstring(&buf, "\n");
  lua_settop(L, 0);

  while (lua_getstack(L, level++, &ar)) {
    if (level >= 20 ||
        (buf.size >= BUF_SIZE_MAX && (buf.size - buf.n < 1024))) {
      luaL_addstring(&buf, "!!!!!! ============= msg size too large");
      break;
    }
    int32_t i = 1;
    const char *name = NULL;
    lua_getinfo(L, "Slnu", &ar);
    name = ar.name ? ar.name : "";
    if ('C' == *ar.what && 
        (0 == strcmp(name, "xpcall") || 0 == strcmp(name, "pcall"))) {
      break;
    }
    lua_pushfstring(buf.L, 
                    "#%d %s %s %s at %s:%d\n", 
                    ++index, 
                    ar.what ? ar.what : "",
                    ar.namewhat ? ar.namewhat : "",
                    ar.name ? ar.name : "",
                    ar.short_src,
                    ar.currentline);
    luaL_addvalue(&buf);

    while ((name = lua_getlocal(L, &ar, i++))) {
      if ('(' == name[0]) {
        lua_pop(L, 1);
        continue;
      }
      lua_pushfstring(buf.L, "  local %s=", name);
      luaL_addvalue(&buf);
      v2str(L, &buf, -1, 0);
      luaL_addstring(&buf, "\n");
      lua_pop(L, 1);
    }
  }
  luaL_addstring(&buf, "------------------------------------------------\n");
  luaL_pushresult(&buf);
  return 1;
}

int32_t luaopen_trace_c(lua_State *L) {
  static const struct luaL_Reg t[] = {
    { "traceback", traceback },
    { NULL, NULL }
  };
  luaL_newlib(L, t);
  return 0;
}
