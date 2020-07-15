/**
 * SKYNET SIMPLE ( https://github.com/viticm/skynet-simple )
 * #id logger.c
 * @link https://github.com/viticm/skynet-simple for the canonical source repository
 * @copyright Copyright (c) 2020 viticm( viticm.ti@gmail.com )
 * @license
 * @user viticm( viticm.ti@gmail.com )
 * @date 2020/07/13 20:25
 * @uses The service logger for skynet.
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <time.h>

#include "skynet.h"
#include "skynet_env.h"
#include "skynet_timer.h"

#define NONE ""
#define CLR "\e[0m"
#define RED "\e[1;31m"
#define GREEN "\e[1;32m"
#define YELLOW "\e[1;33m"
#define CYAN "\e[1;36m"

#define LOGGER_SIZE (10 * 1024 * 1024)

/* Log level defines. */
#define LEVEL_1

#ifdef LEVEL_1
#define FILE_NUM_MAX (2)
const char *color_head[] = {"main", "error"};
#elif LEVEL_2
#define FILE_NUM_MAX (3)
const char *color_head[] = {"main", "error", "warn"};
#elif LEVEL_3
#define FILE_NUM_MAX (4)
const char *color_head[] = {"main", "error", "warn", "debug"};
#else
#define FILE_NUM_MAX (5)
const char *color_head[] = {"main", "error", "warn", "info"};
#endif

struct logger {
  FILE *handle[FILE_NUM_MAX];
  char *filename[FILE_NUM_MAX];
  char *path;
  int8_t close;
  int32_t logsize;
  int32_t filesize[FILE_NUM_MAX];
  int32_t fileindex[FILE_NUM_MAX];
  uint32_t fileday[FILE_NUM_MAX];
};

static int8_t
sameday(time_t t1, time_t t2) {
  struct tm pt1 = *localtime(&t1);
  struct tm pt2 = *localtime(&t2);
  if (pt1.tm_year == pt2.tm_year &&
      pt1.tm_mon == pt2.tm_mon &&
      pt1.tm_mday == pt2.tm_mday) {
    return 0;
  }
  return 1;
}

static uint32_t
filesize(FILE *fp) {
  /*
  struct stat buf;
  int32_t fd = fileno(fp);
  fstat(fd, &buf);
  return buf.st_size;
  */
  uint32_t r = 0;
  uint32_t cur_pos = ftell(fp);
  fseek(fp, 0, SEEK_END);
  r = ftell(fp);
  fseek(fp, cur_pos, SEEK_SET);
  return r;
}

static int32_t
optint(const char *key, int32_t opt) {
  const char *str = skynet_getenv(key);
  if (NULL == str) {
    char tmp[20] = {0,};
    snprintf(tmp, sizeof(tmp) - 1, "%d", opt);
    skynet_setenv(key, tmp);
    return opt;
  }
  return strtol(str, NULL, 10);
}

static uint32_t skynet_time(void) {
  return skynet_starttime() + (uint32_t)(skynet_now() / 100);
}

struct logger *
logger_create(void) {
  struct logger *r = skynet_malloc(sizeof(*r));
  for (uint8_t i = 0; i < FILE_NUM_MAX; ++i) {
    r->handle[i] = NULL;
    r->filename[i] = NULL;
  }
  r->close = 0;
  r->path = NULL;
  return r;
}

void logger_release(struct logger *logger) {
  if (logger->close) {
    for (uint8_t i = 0; i < FILE_NUM_MAX; ++i) {
      if (logger->handle[i]) {
        fclose(logger->handle[i]);
        skynet_free(logger->filename[i]);
      }
    }
  }
  skynet_free(logger);
}

static FILE *
open_logfile(struct logger *logger, uint8_t color) {
  time_t t = skynet_time();
  struct tm *local = localtime(&t);
  char buf[32] = {0, };
  strftime(buf, sizeof(buf) - 1, "%Y%m%d", local);
  char filename[256] = {0, };
  snprintf(filename, 
      sizeof(filename) - 1, 
      logger->path, 
      color_head[color], 
      buf, 
      logger->fileindex[color]);
  logger->handle[color] = fopen(filename, "a");
  logger->filename[color] = skynet_malloc(strlen(filename) + 1);
  strncpy(logger->filename[color], filename, strlen(filename));
  logger->filesize[color] = filesize(logger->handle[color]);
  logger->fileday[color] = skynet_time();
  return logger->handle[color];
}

static FILE *
check_filesize(struct logger *logger, uint8_t color) {
  FILE *handle = logger->handle[color];
  if (handle) {
    for (;;) {
      if (logger->filesize[color] >= logger->logsize) {
        fclose(handle);
        skynet_free(logger->filename[color]);
        logger->fileindex[color] = logger->fileindex[color] + 1;
        handle = open_logfile(logger, color);
      } else {
        break;
      }
    }
    if (sameday(logger->fileday[color], skynet_time()) > 0) {
      if (logger->handle[color]) {
        fclose(logger->handle[color]);
        skynet_free(logger->filename[color]);
      }
      logger->fileindex[color] = 0;
      handle = open_logfile(logger, color);
    }
  } else {
    logger->fileindex[color] = 0;
    handle = open_logfile(logger, color);
  }
  return handle;
}

static int
logger_cb(struct skynet_context *ctx, 
          void *ud, 
          int32_t type, 
          int32_t session, 
          uint32_t source, 
          const void *msg, 
          size_t sz) {
  struct logger *logger = ud;
  uint8_t color = (uint8_t)session;
  switch (type) {
    case PTYPE_SYSTEM:
      if (logger->filename[0]) {
        logger->handle[0] = freopen(logger->filename[0], "a", logger->handle[0]);
      }
      break;
    case PTYPE_TEXT:
      {
        time_t t = skynet_time();
        struct tm *local = localtime(&t);
        char now[32] = {0, };
        strftime(now, sizeof(now) - 1, "%F %T", local);
        if (stdout == logger->handle[0]) {
          char *head = NONE;
          char *end = NONE;
          switch (color) {
            case 1: head = RED; end = CLR; break;
            case 2: head = YELLOW; end = CLR; break;
            case 3: head = CYAN; end = CLR; break;
            case 4: head = GREEN; end = CLR; break;
            default: break;
          }
          fprintf(logger->handle[0], "%s[%08x] %s", now, source, head);
          fwrite(msg, sz, 1, logger->handle[0]);
          fprintf(logger->handle[0], "%s\n", end);
          fflush(logger->handle[0]);
        } else {
          if (color >= FILE_NUM_MAX) {
            color = 0;
          }
          FILE *handle = check_filesize(logger, color);
          if (handle) {
            int32_t length = fprintf(handle, "%s[%08x]", now, source);
            fwrite(msg, sz, 1, handle);
            fprintf(handle, "\n");
            fflush(handle);
            logger->filesize[color] += sz + length + 1;
          }
        }
      }
      break;
  }
  return 0;
}

int32_t 
logger_init(struct logger *logger, 
            struct skynet_context *ctx, 
            const char *param) {
  if (param) {
    for (int32_t i = 0; i < FILE_NUM_MAX; ++i) {
      logger->fileindex[i] = 0;
      logger->filesize[i] = 0;
      logger->fileday[i] = 0;
    }
    logger->path = skynet_malloc(strlen(param) + 1);
    strncpy(logger->path, param, strlen(param));
    open_logfile(logger, 0);
    if (NULL == logger->handle[0]) {
      skynet_free(logger->path);
      return 1;
    }
    logger->logsize = optint("loggersize", LOGGER_SIZE);
    logger->filesize[0] = filesize(logger->handle[0]);
    logger->close = 1;
  } else {
    logger->handle[0] = stdout;
  }
  if (logger->handle[0]) {
    skynet_callback(ctx, logger, logger_cb);
    skynet_command(ctx, "REG", ".logger");
    return 0;
  }
  return 1;
}
