#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <inttypes.h>
#include <memory.h>

#include "zlib.h"
#include "lualib.h"
#include "lauxlib.h"

int
addslashes(const char *in, size_t in_size, char *out, size_t out_size_max) {
  /* maximum string length, worst case situation */
  char *target;
  const char *source, *end;
  size_t offset;

  if (!in || in_size >= out_size_max) {
    return 0;
  }

  source = (char *)in;
  end = source + in_size;

  while (source < end) {
    switch (*source) {
      case '\0':
      case '\'':
      case '\"':
      case '\\':
        goto do_escape;
      default:
        source++;
        break;
    }
  }

  memcpy(out, in, in_size);
  return in_size;
do_escape:
  offset = source - in;
  memcpy(out, in, offset);
  target = out + offset;

  while (source < end) {
    switch (*source) {
      case '\0':
        *target++ = '\\';
        *target++ = '0';
        break;
      case '\'':
      case '\"':
      case '\\':
        *target++ = '\\';
        /* break is missing *intentionally* */
      default:
        *target++ = *source;
        break;
    }
    source++;
  }

  *target = '\0';
  return target - out;
}

int
stripslashes(const char *in, size_t in_size, char *out, size_t out_size_max) {
  if (!in || in_size > out_size_max) return 0;
  size_t len = out_size_max;
  char *str = (char *)in;
  size_t out_len = 0;
  while (len > 0) {
    if (*str == '\\') {
      str++;              /* skip the slash */
      len--;
      if (len > 0) {
        if (*str == '0') {
          *out++='\0';
          str++;
          ++out_len;
        } else {
          *out++ = *str++;    /* preserve the next character */
          ++out_len;
        }
          len--;
        }
    } else {
      *out++ = *str++;
      ++out_len;
      len--;
    }
  }
  return out_len;
}

static int
lua_compress(lua_State *L) {
  size_t len;
  const char *src = luaL_checklstring(L, 1, &len);
  int level = luaL_optinteger(L, 2, 6);
  int32_t save_len = len;
  size_t dstlen = len + 32 + save_len;
  char *dstmem = (char *)malloc(dstlen);
  memset(dstmem, 0, dstlen);
  memcpy(dstmem, (char *)&save_len, sizeof(save_len));
  int r = Z_OK;
  if (dstmem != NULL) {
    r = compress2((Byte *)(dstmem + sizeof(save_len)), 
            &dstlen, (const Bytef *)src, len, level);
    // printf("r: %d|%ld|%ld|%d|%s|\n", r, dstlen, len, level, dstmem);
    if (r == Z_OK) {
      lua_pushlstring(L, dstmem, dstlen + sizeof(save_len));
    }
    free(dstmem);
  }
  return Z_OK == r ? 1 : luaL_error(L, "zip: compress error(%d).", r);
}

static int
lua_uncompress(lua_State *L) {
  size_t len;
  const char *src = luaL_checklstring(L, 1, &len);
  int32_t save_len = 0;
  memcpy((char *)&save_len, src, sizeof(save_len));
  // printf("lua_uncompress:%d\n", save_len);
  if (save_len <= 0) {
    return luaL_error(L, "zip: uncompress the data length error.");
  }
  len = len - sizeof(save_len);
  size_t dstlen = save_len;
  char *dstmem = (char *)malloc(dstlen);
  memset(dstmem, 0, dstlen);
  int r = Z_OK;
  if (dstmem != NULL) {
    r = uncompress2((Byte *)dstmem, &dstlen, 
            (const Bytef *)(src + sizeof(save_len)), &len);
    if (r == Z_OK) {
      lua_pushlstring(L, dstmem, dstlen);
    }
    free(dstmem);
  }
  return Z_OK == r ? 1 : luaL_error(L, "zip: uncompress error(%d).", r);
}

static int
lua_addslashes(lua_State *L) {
  size_t len;
  const char *src = luaL_checklstring(L, 1, &len);
  size_t dstlen = len * 2 + 1;
  char *dstmem = (char *)malloc(dstlen);
  memset(dstmem, 0, dstlen);
  size_t outlen = 0;
  if (dstmem != NULL) {
    outlen = addslashes(src, len, dstmem, dstlen);
    // printf("r: %d|%ld|%ld|%d|%s|\n", r, dstlen, len, level, dstmem);
    if (outlen > 0) {
      lua_pushlstring(L, dstmem, outlen);
    }
    free(dstmem);
  }
  return outlen > 0 ? 1 : luaL_error(L, "zip: addslashes error.");
}

static int
lua_stripslashes(lua_State *L) {
  size_t len;
  const char *src = luaL_checklstring(L, 1, &len);
  size_t dstlen = len;
  char *dstmem = (char *)malloc(dstlen);
  memset(dstmem, 0, dstlen);
  size_t outlen = 0;
  if (dstmem != NULL) {
    outlen = stripslashes(src, len, dstmem, dstlen);
    if (outlen > 0) {
      lua_pushlstring(L, dstmem, outlen);
    }
    free(dstmem);
  }
  return outlen > 0 ? 1 : luaL_error(L, "zip: stripslashes error.");
}

static const struct luaL_Reg lib[] = {
  { "compress",  lua_compress},
  { "uncompress",  lua_uncompress},
  { "addslashes",  lua_addslashes},
  { "stripslashes",  lua_stripslashes},
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
