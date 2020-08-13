LUA_CLIB_PATH ?= luaclib
CSERVICE_PATH ?= cservice
SKYNET_PATH ?= ./skynet
LUA_RAPIDJSON ?= rapidjson
LUA_LFS ?= lfs

# platform
# PLAT ?= linux
# include $(SKYNET_PATH)/platform.mk

SHARED := -fPIC --shared

LUA_INC ?= $(SKYNET_PATH)/3rd/lua/
SKYNET_INC ?= $(SKYNET_PATH)/skynet-src/


CFLAGS = -std=c11 -g -O2 -Wall -I$(LUA_INC) -I$(SKYNET_INC) $(MYCFLAGS)
# CFLAGS += -DUSE_PTHREAD_LOCK

# skynet

CSERVICE = logger
LUA_CLIB = trace \
  print extend minheap split uniq seri

all : \
  $(SKYNET_PATH)/skynet \
	$(LUA_RAPIDJSON) \
	$(LUA_LFS) \
  $(foreach v, $(CSERVICE), $(CSERVICE_PATH)/$(v).so) \
  $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so) 

$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)

$(CSERVICE_PATH) :
	mkdir $(CSERVICE_PATH)

$(LUA_RAPIDJSON) :
	cd 3rd/lua-rapidjson/ && $(MAKE)
	cp 3rd/lua-rapidjson/rapidjson.so $(LUA_CLIB_PATH)

$(LUA_LFS) :
	cd 3rd/lua-filesystem/ && $(MAKE)
	cp 3rd/lua-filesystem/src/lfs.so $(LUA_CLIB_PATH)


define CSERVICE_TEMP
  $$(CSERVICE_PATH)/$(1).so : service-src/service_$(1).c | $$(CSERVICE_PATH)
	$$(CC) $$(CFLAGS) $$(SHARED) $$< -o $$@ -I$(SKYNET_PATH)/skynet-src
endef

$(foreach v, $(CSERVICE), $(eval $(call CSERVICE_TEMP,$(v))))

$(LUA_CLIB_PATH)/trace.so : lualib-src/lua-trace.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

$(LUA_CLIB_PATH)/print.so : lualib-src/lua-print.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

$(LUA_CLIB_PATH)/extend.so : lualib-src/lua-extend.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

$(LUA_CLIB_PATH)/minheap.so : lualib-src/lua-minheap.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

$(LUA_CLIB_PATH)/split.so : lualib-src/lua-split.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

$(LUA_CLIB_PATH)/uniq.so : lualib-src/lua-uniq.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

$(LUA_CLIB_PATH)/seri.so : lualib-src/lua-seri.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

$(SKYNET_PATH)/skynet :
	cd $(SKYNET_PATH) && $(MAKE) linux

clean :
	cd $(SKYNET_PATH) && $(MAKE) clean
	rm -f $(CSERVICE_PATH)/*.so $(LUA_CLIB_PATH)/*.so

cleanall :
	cd $(SKYNET_PATH) && $(MAKE) cleanall
	rm -f $(CSERVICE_PATH)/*.so $(LUA_CLIB_PATH)/*.so
	cd 3rd/lua-rapidjson/ && $(MAKE) clean
	cd 3rd/lua-filesystem/ && $(MAKE) clean
