/**
 * SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 * $Id lua-minheap.c
 * @link https://github.com/viticm/skynet-simple for the canonical source repository
 * @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 * @license
 * @user viticm( viticm.ti@gmail.com )
 * @date 2020/08/05 14:51
 * @uses A c library for lua.
 *       !ref: https://github.com/hongling0/lualibs
 */
#include <stdlib.h>
#include <lua.h>
#include <lauxlib.h>

#define COMPARE_NODE(a,b,op) ((a)->expire) op ((b)->expire)

struct node {
  int64_t expire;
  int64_t value;
};

struct min_heap {
  size_t cap;
  size_t num;
  struct node *array;
};

static inline void
heap_resize(struct min_heap *heap) {
  size_t cap, ncap, i;
  struct node *array, *narray;

  cap = heap->cap;
  array = heap->array;
  ncap = cap > 0 ? (cap << 1) : 64 ;
  narray = (struct node*)malloc(sizeof(*narray) * (ncap));
  for (i = 0; i < cap; i++) {
    narray[i] = array[i];
  }
  heap->array = narray;
  heap->cap = ncap;
  free(array);
}

static inline  void
heap_shiftup(struct min_heap *heap, size_t hole, struct node * val) {
  struct node *array = heap->array;
  while (hole > 0) {
    size_t parent = (hole - 1) / 2;
    if (COMPARE_NODE(&array[parent], val, < )) {
      break;
    }
    array[hole] = array[parent];
    hole = parent;
  }
  array[hole] = *val;
}

static inline void
heap_shiftdown(struct min_heap *heap, size_t hole, struct node* val) {
  struct node *array = heap->array;
  size_t num = heap->num;
  size_t half = num / 2;
  while (hole < half) {
    size_t child = 2 * hole + 1;
    size_t right = child + 1;
    if (right < num && COMPARE_NODE(&array[child], &array[right], > )) {
      child = right;
    }
    if (COMPARE_NODE(val, &array[child], < )) {
      break;
    }
    array[hole] = array[child];
    hole = child;
  }
  array[hole] = *val;
}

static inline void
heap_add(struct min_heap *heap, struct node* val) {
  if ((heap->num + 1) >= heap->cap ) {
    heap_resize(heap);
  }
  heap_shiftup(heap, heap->num++, val);
}

static inline void
heap_free(struct min_heap *heap) {
  free(heap->array);
}

static inline struct node*
heap_top(struct min_heap * heap) {
  if (heap->num == 0) {
    return NULL;
  }
  return &heap->array[0];
}

static inline struct node*
heap_pop(struct min_heap * heap, int64_t expire, struct node* out) {
  struct node* min = heap_top(heap);
  if (min && min->expire <= expire) {
    *out = *min;
    heap_shiftdown(heap, 0, &heap->array[--heap->num]);
    return out;
  }
  return  NULL;
}

static inline struct min_heap *
lcheck_timeheap(lua_State *L, int idx) {
  struct min_heap * heap = (struct min_heap *)lua_touserdata(L, idx);
  if (!heap) {
    luaL_error(L, 
        "expected a min_heap but got a %s(#%d)", 
        luaL_typename(L, idx), idx);
  }
  return heap;
}

static int
lminheap_gc(lua_State *L) {
  struct min_heap * heap = lcheck_timeheap(L, 1);
  heap_free(heap);
  return 1;
}

static int
lminheap_new(lua_State *L) {
  struct min_heap *heap;
  heap = (struct min_heap*)lua_newuserdata(L, sizeof(*heap));
  heap->array = NULL;
  heap->cap = heap->num = 0;
  lua_createtable(L, 0, 1);
  lua_pushliteral(L, "__gc");
  lua_pushcfunction(L, lminheap_gc);
  lua_rawset(L, -3);
  lua_setmetatable(L, -2);
  return 1;
}

static int
lminheap_add(lua_State *L) {
  struct min_heap * heap = lcheck_timeheap(L, 1);
  int64_t value = luaL_checkinteger(L, 2);
  int64_t expire = luaL_checkinteger(L, 3);
  struct node n = {.expire = expire, .value = value};
  heap_add(heap, &n);
  return 0;
}

static int
lminheap_pop(lua_State *L) {
  struct min_heap * heap = lcheck_timeheap(L, 1);
  int64_t expire = luaL_checkinteger(L, 2);
  struct node n;
  if (heap_pop(heap, expire, &n)) {
    lua_pushinteger(L, n.value);
    lua_pushinteger(L, n.expire);
    return 2;
  }
  return 0;
}

static int
lminheap_top(lua_State *L) {
  struct min_heap * heap = lcheck_timeheap(L, 1);
  struct node *n = heap_top(heap);
  if (n) {
    lua_pushinteger(L, n->value);
    lua_pushinteger(L, n->expire);
    return 2;
  }
  return 0;
}

static int
lminheap_size(lua_State *L) {
  struct min_heap * heap = lcheck_timeheap(L, 1);
  lua_pushinteger(L, heap->num);
  return 1;
}



int luaopen_minheap_c(lua_State*L) {
  static const struct luaL_Reg lib[] = {
    {"new", lminheap_new},
    {"add", lminheap_add},
    {"pop", lminheap_pop},
    {"top", lminheap_top},
    {"size", lminheap_size},
    {NULL, NULL}
  };
  luaL_newlib(L, lib);
  return 1;
}
