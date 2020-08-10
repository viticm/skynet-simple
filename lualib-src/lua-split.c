/**
 * SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 * $Id lua-split.c
 * @link https://github.com/viticm/skynet-simple for the canonical source repository
 * @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 * @license
 * @user viticm( viticm.ti@gmail.com )
 * @date 2020/08/05 15:08
 * @uses A split string library for lua.
 *       !ref: https://github.com/hongling0/lualibs
 */
#include <string.h>
#include <lauxlib.h>

typedef void(split_callback)(void *ctx, const char *s, size_t len);

static void 
do_split(const char *source, 
         size_t len, 
         const char *sp, 
         split_callback call, 
         void *ctx) {
  if (len != 0) {
    if (!(*sp)) {
      call(ctx, source, len);
    } else {
      const char *src = source;
      const char *end = strstr(src, sp);
      while (end && *end){
        call(ctx, src, end - src);
        src = ++end;
        end = strstr(src, sp);
      }
      call(ctx, src, len - (src - source));
    }
  }
}

struct luasplit_ctx{
  lua_State *L;
  int index;
  int opt;
};

static void 
luasplit2table(void *ctx, const char *src, size_t len) {
  struct luasplit_ctx *lctx = (struct luasplit_ctx *)ctx;
  if (lctx->opt == 0 || len > 0){
    lua_pushlstring(lctx->L, src,len);
    lua_rawseti(lctx->L, -2, ++lctx->index);
  }
}

static void 
luasplit2stack(void *ctx,const char *src, size_t len) {
  struct luasplit_ctx *lctx = (struct luasplit_ctx *)ctx;
  if (lctx->opt == 0 || len > 0) {
    lua_pushlstring(lctx->L, src, len);
    ++lctx->index;
  }
}

static int 
split2table(lua_State *L) {
  size_t len;
  const char *src = luaL_checklstring(L, 1, &len);
  const char *sp = luaL_optstring(L, 2, " ");
  static const char * const optname[] = {"a", "i", NULL};
  int op = luaL_checkoption(L, 3, "a", optname);
  struct luasplit_ctx lctx = {L, 0, op};
  lua_newtable(L);
  do_split(src, len, sp, luasplit2table, &lctx);
  return 1;
}

static int 
split2stack(lua_State *L) {
  size_t len;
  const char *src = luaL_checklstring(L, 1, &len);
  const char *sp = luaL_optstring(L, 2, " ");
  static const char * const optname[] = {"a", "i", NULL};
  int op = luaL_checkoption(L, 3, "a", optname);
  struct luasplit_ctx lctx = {L, 0, op};
  do_split(src, len, sp, luasplit2stack, &lctx);
  return lctx.index;
}

int 
luaopen_split_c(lua_State*L) {
  static const struct luaL_Reg lib[] = {
    {"split", split2table},
    {"splitrow", split2stack},
    {NULL, NULL}
  };
  luaL_newlib(L, lib);
  return 1;
}
