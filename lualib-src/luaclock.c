#include <stdio.h>    
#include <sys/time.h>
#include <lua.h>
#include <lauxlib.h>

static int
getCurrentTime(lua_State *L)    
{    
	struct timeval tv;  ;	
	gettimeofday(&tv, NULL);  
	double t = tv.tv_sec + tv.tv_usec/1000000.0;
	lua_pushnumber(L, t);
	return 1;
}    

LUAMOD_API int
luaopen_luaclock(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] ={
		{ "time", getCurrentTime },
		{ NULL, NULL },
	};

	luaL_newlib(L,l);
	return 1;
}