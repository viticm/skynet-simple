/**
 * SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 * $Id lua-uniq.c
 * @link https://github.com/viticm/skynet-simple for the canonical source repository
 * @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 * @license
 * @user viticm( viticm.ti@gmail.com )
 * @date 2020/08/05 14:58
 * @uses A simple unique id generate library.
 *       !ref: https://github.com/hongling0/lualibs
 */
#include <inttypes.h>
#include <stdint.h>
#include <time.h>

#include <lualib.h>
#include <lauxlib.h>


#define UNIQ_MAIN_SHIFT 14  // 16384
#define UNIQ_TYPE_SHIFT 3   // 8 type
#define UNIQ_TIME_SHIFT 28  // 8.5 years
#define UNIQ_INCR_SHIFT 18  // 262144

#define UNIQ_MAIN (1UL<<UNIQ_MAIN_SHIFT)
#define UNIQ_TYPE (1UL<<UNIQ_TYPE_SHIFT)
#define UNIQ_TIME (1UL<<UNIQ_TIME_SHIFT)
#define UNIQ_INCR (1UL<<UNIQ_INCR_SHIFT)

#define UNIQ_MAIN_MASK ((UNIQ_MAIN-1)<<(UNIQ_INCR_SHIFT+UNIQ_TIME_SHIFT+UNIQ_TYPE_SHIFT))
#define UNIQ_TYPE_MASK ((UNIQ_TIME-1)<<(UNIQ_INCR_SHIFT+UNIQ_TIME_SHIFT))
#define UNIQ_TIME_MASK ((UNIQ_TIME-1)<<(UNIQ_INCR_SHIFT))
#define UNIQ_INCR_MASK ((UNIQ_INCR-1))

static uint32_t main_id;
static uint64_t last_sec;
static uint64_t last_inc;
static volatile uint32_t inc;
static int lock = 0;

#define LOCK(l) do{__sync_lock_test_and_set(l,1);} while(0)
#define UNLOCK(l) do{__sync_lock_release(l);}while(0)

static inline uint64_t
genid(uint64_t type) {
	LOCK(&lock);
	uint64_t now = (uint64_t)time(NULL);
	if (last_inc == inc) {
		if (last_sec == now) {
			UNLOCK(&lock);
			return 0;
		} else {
			last_sec = now;
			last_inc = inc;
		}
	}
	if (++inc >= UNIQ_INCR) {
		inc = 0;
	}
	uint64_t inc_id = inc;
	UNLOCK(&lock);

	return (((uint64_t)main_id << (UNIQ_TYPE_SHIFT + 
          UNIQ_TIME_SHIFT + UNIQ_INCR_SHIFT)) & UNIQ_MAIN_MASK)
	       | ((type << (UNIQ_TIME_SHIFT + UNIQ_INCR_SHIFT))&UNIQ_TYPE_MASK)
	       | ((now << (UNIQ_INCR_SHIFT))&UNIQ_TIME_MASK)
	       | (inc_id & UNIQ_INCR_MASK);
}

static inline const char*
uint64_str(uint64_t u, char tmp[17]) {
	static char c[] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 
    'A', 'B', 'C', 'D', 'E', 'F'};
	int i = 0;
	for (; i < 16; i++) {
		tmp[i] = c[u >> (15 - i) * 4 & 0xf];
	}
	return tmp;
}

static int
luauniq_init(lua_State * L) {
	unsigned int id = (uint64_t)luaL_checkinteger(L, 1);
	if (id >= UNIQ_MAIN) {
		luaL_error(L, "main_id must less than %d", (int)(UNIQ_MAIN));
	}
	main_id = id;
	last_sec = 0;
	last_inc = 0;
	inc = 0;
	return 1;
}

static inline int
check_type(lua_State *L, int idx) {
	unsigned int t = (unsigned int)luaL_checkinteger(L, idx);
	if (t >= UNIQ_TYPE) {
		luaL_error(L, "type error must less than %d", (int)(1 << UNIQ_TYPE));
	}
	return t;
}

#define GEN_ID(tp,val,L) \
do { val=genid(tp);\
if(val==0)\
	luaL_error(L,"max support register %d uniqid per second",(int)(UNIQ_INCR-1));\
}while(0)

static int luauniq_genid(lua_State * L) {
	int64_t val;
	GEN_ID(check_type(L, 1), val, L);
	lua_pushinteger(L, val);
	return 1;
}

static int luauniq_gennums(lua_State * L) {
	char tmp[36] = {0};
	int64_t val;
	lua_Integer bit = luaL_optinteger(L, 2, 10);
	GEN_ID(check_type(L, 1), val, L);
	switch (bit) {
	case 16:
		sprintf(tmp, "%" PRIx64, val);
		break;
	case 10:
		sprintf(tmp, "%" PRIu64, val);
		break;
	case 8:
		sprintf(tmp, "%" PRIo64, val);
		break;
	default:
		luaL_error(L, "unsupport bit transform %d", bit);
		break;
	}
	lua_pushstring(L, tmp);
	return 1;
}

static int luauniq_genstr(lua_State *L) {
	int64_t val;
	char tmp[17] = {0};
	GEN_ID(check_type(L, 1), val, L);
	uint64_str(val, tmp);
	lua_pushstring(L, tmp);
	return 1;
}

int luaopen_uniq_c(lua_State * L) {
	static const struct luaL_Reg lib[] = {
		{"init", luauniq_init},
		{"id", luauniq_genid},
		{"str", luauniq_genstr},
		{"num", luauniq_gennums},
		{NULL, NULL}
	};
	luaL_newlib(L, lib);
	return 1;
}

