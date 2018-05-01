include ../skynet/platform.mk

CC ?= gcc

SHARED := -fPIC --shared

LUA_CLIB_PATH ?= ../luaclib
SKYNET_BUILD_PATH ?= ../skynet

CFLAGS = -g -O2 -Wall -I$(LUA_INC) 

LUA_STATICLIB := ../skynet/3rd/lua/liblua.a
LUA_LIB ?= $(LUA_STATICLIB)
LUA_INC ?= ../skynet/3rd/lua


LUA_CLIB = cjson websocketnetpack clientwebsocket lfs hash

all	: $(LUA_CLIB_PATH)/cjson.so $(LUA_CLIB_PATH)/websocketnetpack.so $(LUA_CLIB_PATH)/clientwebsocket.so \
		$(LUA_CLIB_PATH)/lfs.so $(LUA_CLIB_PATH)/luaclock.so $(LUA_CLIB_PATH)/hash.so 

$(LUA_CLIB_PATH)/cjson.so : lua-cjson/fpconv.c lua-cjson/strbuf.c lua-cjson/lua_cjson.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -Ilua-cjson $^ -o $@

$(LUA_CLIB_PATH)/websocketnetpack.so : lua-websocketnetpack.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -I$(SKYNET_BUILD_PATH)/skynet-src $^ -o $@

$(LUA_CLIB_PATH)/clientwebsocket.so : lua-clientwebsocket.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -lpthread

$(LUA_CLIB_PATH)/lfs.so : luafilesystem/src/lfs.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) -Iluafilesystem/src $^ -o $@

$(LUA_CLIB_PATH)/luaclock.so : luaclock.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ -lpthread

$(LUA_CLIB_PATH)/hash.so : lua-hash.c | $(LUA_CLIB_PATH)
	$(CC) $(CFLAGS) $(SHARED) $^ -o $@ 

clean :
	rm -f $(LUA_CLIB_PATH)/*.so

