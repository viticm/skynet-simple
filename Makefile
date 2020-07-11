LUA_CLIB_PATH ?= luaclib
CSERVICE_PATH ?= cservice
SKYNET_PATH ?= ./skynet

# platform
# PLAT ?= linux
# include $(SKYNET_PATH)/platform.mk

SHARED := -fPIC --shared

LUA_INC ?= $(SKYNET_PATH)/3rd/lua/
SKYNET_INC ?= $(SKYNET_PATH)/skynet-src/


CFLAGS = -g -O2 -Wall -I$(LUA_INC) -I$(SKYNET_INC) $(MYCFLAGS)
# CFLAGS += -DUSE_PTHREAD_LOCK

# skynet

CSERVICE = 
LUA_CLIB = trace

all : \
  $(SKYNET_PATH)/skynet \
  $(foreach v, $(CSERVICE), $(CSERVICE_PATH)/$(v).so) \
  $(foreach v, $(LUA_CLIB), $(LUA_CLIB_PATH)/$(v).so) 

$(LUA_CLIB_PATH) :
	mkdir $(LUA_CLIB_PATH)

$(CSERVICE_PATH) :
	mkdir $(CSERVICE_PATH)

define CSERVICE_TEMP
  $$(CSERVICE_PATH)/$(1).so : service-src/service_$(1).c | $$(CSERVICE_PATH)
	$$(CC) $$(CFLAGS) $$(SHARED) $$< -o $$@ -I$(SKYNET_PATH)/skynet-src
endef

$(foreach v, $(CSERVICE), $(eval $(call CSERVICE_TEMP,$(v))))

$(LUA_CLIB_PATH)/trace.so : lualib-src/lua-trace.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

$(SKYNET_PATH)/skynet :
	cd $(SKYNET_PATH) && $(MAKE) linux

clean :
	cd $(SKYNET_PATH) && $(MAKE) clean
	rm -f $(CSERVICE_PATH)/*.so $(LUA_CLIB_PATH)/*.so

cleanall :
	cd $(SKYNET_PATH) && $(MAKE) cleanall
	rm -f $(CSERVICE_PATH)/*.so $(LUA_CLIB_PATH)/*.so
