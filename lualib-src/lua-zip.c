/**
 * SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 * $Id lua-zip.c
 * @link https://github.com/viticm/skynet-simple for the canonical source repository
 * @copyright Copyright (c) 2021 viticm( viticm.ti@gmail.com )
 * @license
 * @user viticm( viticm.ti@gmail.com )
 * @date 2021/07/30 23:22
 * @uses The ZIP(zlib) for lua lib.
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <inttypes.h>

#include "zlib.h"
#include "lualib.h"
#include "lauxlib.h"

/*
	zlib utility functions
*/

void *
zlib_alloc(void *opaque, unsigned int items, unsigned int size) {
	return calloc(items, size);
}

void zlib_free(void *opaque, void *address) {
	free(address);
}

int
zlib_compress(const char *in, size_t size_in, char *out, size_t size_out) {
	z_stream *stream;
	int len;

	stream = calloc(1, sizeof(z_stream));

	stream->next_in     = (unsigned char *) in;
	stream->avail_in    = size_in;

	stream->next_out    = (unsigned char *) out;
	stream->avail_out   = size_out - 1;

	stream->data_type   = Z_ASCII;
	stream->zalloc      = zlib_alloc;
	stream->zfree       = zlib_free;
	stream->opaque      = Z_NULL;

	if (deflateInit(stream, Z_BEST_COMPRESSION) != Z_OK) {
		printf("zlib_compress: failed deflateInit2\n");
		free(stream);
		return -1;
	}

	if (deflate(stream, Z_FINISH) != Z_STREAM_END) {
		printf("zlib_compress: failed deflate\n");
		free(stream);
		return -1;
	}

	if (deflateEnd(stream) != Z_OK) {
		printf("zlib_compress: failed deflateEnd\n");
		free(stream);
		return -1;
	}

	len = size_out - stream->avail_out;
	free(stream);
	return len;
}

int
zlib_decompress(const char *in, size_t size_in, char *out, size_t size_out) {
	z_stream *stream;
	int len;

	stream = calloc(1, sizeof(z_stream));

	stream->data_type   = Z_ASCII;
	stream->zalloc      = zlib_alloc;
	stream->zfree       = zlib_free;
	stream->opaque      = Z_NULL;

	if (inflateInit(stream) != Z_OK) {
		printf("zlib_decompresss: failed inflateInit\n");
		free(stream);
		return -1;
	}

	stream->next_in     = (unsigned char *) in;
	stream->avail_in    = size_in;

	stream->next_out    = (unsigned char *) out;
	stream->avail_out   = size_out - 1;

	if (inflate(stream, Z_SYNC_FLUSH) == Z_BUF_ERROR) {
		printf("zlib_decompress: inflate Z_BUF_ERROR\n");
		len = -1;
	} else {
		len = stream->next_out - (unsigned char *) out;
		out[len] = 0;
	}

	inflateEnd(stream);
	free(stream);
	return len;
}

/*
	Base252 utility functions
*/

// zlib compress data, next convert data to base252
// returns size of out, not including null-termination
int
data_to_base252(const char *in, size_t size_in, char *out, size_t size_out) {
	char *buf, *pto;
	int len, cnt;

	buf = malloc(size_in * 2);

	len = zlib_compress(in, size_in, buf, size_out);

	if (len == -1) {
		return -1;
	}

	pto = out;

	for (cnt = 0 ; cnt < len ; cnt++) {
		if (pto - out >= size_out - 2) {
			break;
		}

		switch ((unsigned char) buf[cnt]) {
			case 0:
			case '"':
				*pto++ = 245;
				*pto++ = 128 + (unsigned char) buf[cnt] % 64;
				break;

			case '\\':
				*pto++ = 246;
				*pto++ = 128 + (unsigned char) buf[cnt] % 64;
				break;

			case 245:
			case 246:
			case 247:
			case 248:
				*pto++ = 248;
				*pto++ = 128 + (unsigned char) buf[cnt] % 64;
				break;

			default:
				*pto++ = buf[cnt];
				break;
		}
	}

	*pto = 0;

	free(buf);

	return pto - out;
}

// unconvert data from base252, next zlib decompress data
// returns size of out, not including null-termination
int
base252_to_data(const char *in, size_t size_in, char *out, size_t size_out) {
	char *buf, *ptb;
	int val, cnt;

	buf = malloc(size_in);

	ptb = buf;
	cnt = 0;

	while (cnt < size_in) {
		switch ((unsigned char) in[cnt]) {
			default:
				*ptb++ = in[cnt++];
				continue;

			case 245:
				*ptb++ = 0 + (unsigned char) in[++cnt] % 64;
				break;

			case 246:
				*ptb++ = 64 + (unsigned char) in[++cnt] % 64;
				break;

			case 247:
				*ptb++ = 128 + (unsigned char) in[++cnt] % 64;
				break;

			case 248:
				*ptb++ = 192 + (unsigned char) in[++cnt] % 64;
				break;
		}

		if (cnt < size_in) {
			cnt++;
		}
	}

	val = zlib_decompress(buf, ptb - buf, out, size_out);

	free(buf);

	return val;
}


static int
lua_compress(lua_State *L) {
  size_t len;
  const char *src = luaL_checklstring(L, 1, &len);
  int level = luaL_optinteger(L, 2, 6);
  size_t dstlen;
  char *dstmem = (char *)malloc(len + 32);
  memset(dstmem, 0, len + 32);
  int r = Z_OK;
  if (dstmem != NULL) {
    r = compress2((Byte *)dstmem, &dstlen, (const Bytef *)src, len, level);
    // printf("r: %d|%ld|%ld|%d|%s|\n", r, dstlen, len, level, dstmem);
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

static int
lua_encode252(lua_State *L) {
  size_t len;
  const char *src = luaL_checklstring(L, 1, &len);
  size_t dstlen = len + 32;
  char *dstmem = (char *)malloc(dstlen);
  memset(dstmem, 0, dstlen);
  size_t outlen = 0;
  if (dstmem != NULL) {
    outlen = data_to_base252(src, len, dstmem, dstlen);
    // printf("r: %d|%ld|%ld|%d|%s|\n", r, dstlen, len, level, dstmem);
    if (outlen > 0) {
      lua_pushlstring(L, dstmem, outlen);
    }
    free(dstmem);
  }
  return outlen > 0 ? 1 : luaL_error(L, "zip: compress error.");
}

static int
lua_decode252(lua_State *L) {
  size_t len;
  const char *src = luaL_checklstring(L, 1, &len);
  size_t dstlen = len * 5;
  char *dstmem = (char *)malloc(dstlen);
  memset(dstmem, 0, dstlen);
  size_t outlen = 0;
  if (dstmem != NULL) {
    outlen = base252_to_data(src, len, dstmem, dstlen);
    if (outlen > 0) {
      lua_pushlstring(L, dstmem, outlen);
    }
    free(dstmem);
  }
  return outlen > 0 ? 1 : luaL_error(L, "zip: uncompress error.");
}


static const struct luaL_Reg lib[] = {
  { "compress",  lua_compress},
  { "uncompress",  lua_uncompress},
  { "encode252",  lua_encode252},
  { "decode252",  lua_decode252},
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
