/**
 * SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 * #id lua-extend.c
 * @link https://github.com/viticm/skynet-simple for the canonical source repository
 * @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 * @license
 * @user viticm( viticm.ti@gmail.com )
 * @date 2020/07/14 14:46
 * @uses The extend table.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#include "skynet_timer.h"

static unsigned int 
num_escape_sql_str(unsigned char *dest, unsigned char * src, size_t sz) {
  unsigned int n = 0;
  while (sz) {
    if (0 == (0x80 & *src)) {
      switch (*src) {
        case '\0':
        case '\b':
        case '\n':
        case '\r':
        case '\t':
        case 26:
        case '\\':
        case '\'':
        case '"':
          ++n;
          break;
        default:
          break;
      }
    }
    ++src;
    --sz;
  }
  return n;
}

static unsigned char *
escape_sql_str(unsigned char *dest, unsigned char *src, size_t sz) {
  while (sz) {
    if (0 == (0x80 & *src)) {
      switch (*src) {
        case '\0':
          *dest++ = '\\';
          *dest++ = '0';
          break;
        case '\b':
          *dest++ = '\\';
          *dest++ = 'b';
          break;
        case '\n':
          *dest++ = '\\';
          *dest++ = 'n';
          break;
        case '\r':
          *dest++ = '\\';
          *dest++ = 'r';
          break;
        case '\t':
          *dest++ = '\\';
          *dest++ = 't';
          break;
        case 26:
          *dest++ = '\\';
          *dest++ = 'Z';
          break;
        case '\\':
          *dest++ = '\\';
          *dest++ = '\\';
          break;
        case '\'':
          *dest++ = '\\';
          *dest++ = '\'';
          break;
        case '"':
          *dest++ = '\\';
          *dest++ = '"';
          break;
        default:
          *dest++ = *src;
          break;
      }
    } else {
      *dest++ = *src;
    }
    ++src;
    --sz;
  }
  return dest;
}

static int
quote_sql_str(lua_State *L) {
  size_t len, dlen, escape;
  unsigned char *p;
  unsigned char *src, *dest;
  if (lua_gettop(L) != 1) {
    return luaL_error(L, "quote_sql_str need one arg");
  }
  src = (unsigned char *)luaL_checklstring(L, 1, &len);
  if (0 == len) {
    dest = (unsigned char *)"\"\"";
    dlen = sizeof("\"\"") - 1;
    lua_pushlstring(L, (char *)dest, dlen);
    return 1;
  }
  escape = num_escape_sql_str(NULL, src, len);
  dlen = sizeof("\"\"") - 1 + len + escape;
  p = lua_newuserdata(L, dlen);
  dest = p;
  *p++ = '"';
  if (0 == escape) {
    memcpy(p, src, len);
    p += len;
  } else {
    p = (unsigned char *)escape_sql_str(p, src, len);
  }
  *p++ = '"';
  if (p != dest + dlen) {
    return luaL_error(L, "quote_sql_str error");
  }
  lua_pushlstring(L, (char *)dest, p - dest);
  return 1;
}

int
luaopen_extend_c(lua_State*L) {
  static const struct luaL_Reg lib[] = {
    {"quote_sql_str", quote_sql_str},
    {NULL, NULL}
  };
  luaL_newlib(L, lib);
  return 1;
}
