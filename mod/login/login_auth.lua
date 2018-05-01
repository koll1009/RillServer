local skynet    = require "skynet"
local httpc     = require "http.httpc"
local md5        = require "md5"
local json      = require "cjson"

local libdbproxy = require "libdbproxy"
local platfrom  = require "login.platfrom"

--sdk 列表 1为内联 2为debug
local sdk     = {
    inner       = 1,
    debug       = 2,
}

--返回true,uid/false 
local function register(account, password)
	if not account then
		ERROR("register not account" )
        return false
	end
    local ret = libdbproxy.get_accountdata(account)
    if ret then
        return false
    end

    local uid = libdbproxy.inc_uid() 
    local data = {
        uid = uid,
        account = account,
        password = password,
        sdk = sdk.inner
    }

    local ret = libdbproxy.set_accountdata(account, data) 
    INFO("register succ account: ", account, " uid:", uid)
    return true, uid
end

--返回true,uid/false 
local function check_normal_sdk(account, password)
	if not account then
		ERROR("check_pw not account")
        return false
	end

    local ret = libdbproxy.get_accountdata(account)
	--登录
	if ret and ret.password == password then
		INFO(string.format("check_pw succ account:%s then login uid: %d", account, ret.uid) )
		return true, ret.uid
	end
	--注册
	INFO(string.format("check_pw fail account:%s then register",  account))
	local ret, uid = register(account, password)
	if ret then
		return true, uid
	end

	return false
end

local function inner_auth(openId, userdata)
    local account = userdata.account
    local password = userdata.password
    
    return check_normal_sdk(account, password)
end

local function debug_auth(openId, userdata)
    -- local appkey = "NGE8sVGVy3rvY4e6GflP3vdbCdo830qHxVa"
    -- local sign = md5.sumhexa(openId .. appkey)
    -- if sign ~= userdata then
    --     skynet.error(sign, userdata, " is not equal")
    --     return false
    -- end
    -- local uin_info = redisx.hgettable("account:uin_info", openId)
    -- if uin_info == nil then
    --     skynet.error("not this user in db")
    -- end
    -- return uin_info ~= nil
end


local auth_handler = {
    [sdk.inner] = inner_auth,
    [sdk.debug] = debug_auth,
}

return function(sdk, userdata)
    local fc = auth_handler[sdk]
    local openId = userdata.openId or ""
    return fc(openId, userdata)
end
