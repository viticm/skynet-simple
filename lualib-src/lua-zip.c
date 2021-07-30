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
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <inttypes.h>

#include "zlib.h"
#include "lualib.h"
#include "lauxlib.h"

#define MESSAGE_SIZE_MAX (256)

static int
lua_compress(lua_State *L) {
  size_t len;
  const char *src = luaL_checklstring(L, 1, &len);
  int level = luaL_optinteger(L, 2, 6);
  size_t dstlen;
  char *dstmem = (char *)malloc(len + 1);
  memset(dstmem, 0, len + 1);
  int r = Z_OK;
  if (dstmem != NULL) {
    r = compress2((Byte *)dstmem, &dstlen, (const Bytef *)src, len, level);
    printf("r: %d|%ld|%ld|%d|%s|\n", r, dstlen, len, level, dstmem);
    if (r == Z_OK) {
      lua_pushlstring(L, dstmem, dstlen);
    }
    free(dstmem);
  }
  return Z_OK == r ? 1 : luaL_error(L, "zip: compress error.");
}

static int
lua_uncompress(lua_State *L) {
  size_t len;
  const char *src = luaL_checklstring(L, 1, &len);
  size_t dstlen = len * 5;
  char *dstmem = (char *)malloc(dstlen);
  memset(dstmem, 0, dstlen);
  int r = Z_OK;
  if (dstmem != NULL) {
    r = uncompress2((Byte *)dstmem, &dstlen, (const Bytef *)src, &len);
    if (r == Z_OK) {
      lua_pushlstring(L, dstmem, dstlen);
    }
    free(dstmem);
  }
  return Z_OK == r ? 1 : luaL_error(L, "zip: uncompress error.");
}

static const struct luaL_Reg lib[] = {
  { "compress",  lua_compress},
  { "uncompress",  lua_uncompress},
  { NULL, NULL }
};

int32_t
luaopen_zip_c(lua_State *L) {
#if LUA_VERSION_NUM >= 502
  luaL_newlib(L, lib);
#else
  luaL_register(L, "zip", lib);
#endif
  return 1;
}
