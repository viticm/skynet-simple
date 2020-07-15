/**
 * SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 * $Id lua-print.c
 * @link https://github.com/viticm/skynet-simple for the canonical source repository
 * @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 * @license
 * @user viticm( viticm.ti@gmail.com )
 * @date 2020/07/13 10:40
 * @uses The print extend for skynet.
 */
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <inttypes.h>

#include "lualib.h"
#include "lauxlib.h"

#include "skynet.h"
#include "skynet_handle.h"
#include "skynet_mq.h"
#include "skynet_server.h"

#define MESSAGE_SIZE_MAX (256)

void
skynet_print(struct skynet_context *context, 
             int32_t type, 
             const char *msg, 
             ...) {
  static uint32_t print = 0;
  if (0 == print)
    print = skynet_handle_findname("logger");
  if (0 == print) return;

  char tmp[MESSAGE_SIZE_MAX] = {0, };
  char *data = NULL;

  va_list ap;
  va_start(ap, msg);
  int32_t length = vsnprintf(tmp, MESSAGE_SIZE_MAX - 1, msg, ap);
  va_end(ap);

  if (length > 0 && length < MESSAGE_SIZE_MAX) {
    data = skynet_strdup(tmp);
  } else {
    int32_t size_max = MESSAGE_SIZE_MAX;
    for (;;) {
      size_max *= 2;
      data = skynet_malloc(size_max);
      va_start(ap, msg);
      length = vsnprintf(data, size_max, msg, ap);
      va_end(ap);
      if (length < size_max) break;
      skynet_free(data);
    }
  }
  if (length < 0) {
    skynet_free(data);
    perror("vsnprintf error: ");
    return;
  }

  struct skynet_message smsg;
  if (NULL == context) {
    smsg.source = 0;
  } else {
    smsg.source = skynet_context_handle(context);
  }
  smsg.session = type;
  smsg.data = data;
  smsg.sz = length | ((size_t)PTYPE_TEXT << MESSAGE_TYPE_SHIFT);
  skynet_context_push(print, &smsg);
}

static int
lua_print(lua_State *L) {
  struct skynet_context *context = lua_touserdata(L, lua_upvalueindex(1));
  int32_t type = luaL_checkinteger(L, 1);
  int32_t n = lua_gettop(L);
  if (n <= 2) {
    lua_settop(L, 2);
    const char *str = luaL_tolstring(L, 2, NULL);
    skynet_print(context, type, "%s", str);
    return 0;
  }

  luaL_Buffer buf;
  luaL_buffinit(L, &buf);
  int32_t i = 0;
  for (i = 2; i <= n; ++i) {
    luaL_tolstring(L, i, NULL);
    luaL_addvalue(&buf);
    if (i < n)
      luaL_addchar(&buf, ' ');
  }
  return 0;
}

int32_t
luaopen_print_c(lua_State *L) {
  static const struct luaL_Reg lib[] = {
    { "print", lua_print },
    { NULL, NULL }
  };
  luaL_newlib(L, lib);
  lua_getfield(L, LUA_REGISTRYINDEX, "skynet_context");
  struct skynet_context *ctx = lua_touserdata(L, -1);
  if (NULL == ctx) {
    return luaL_error(L, "depend on the skynet context");
  }
  luaL_setfuncs(L, lib, 1);
  return 1;
}
