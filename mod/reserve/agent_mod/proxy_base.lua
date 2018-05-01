local rawget, rawset, setmetatable = rawget, rawset, setmetatable
local pairs, ipairs, type = pairs, ipairs, type

local skynet = require "skynet"
local hash   = require "hash"


local M = {}
M.__index = M

function M:_loadDB(uin, ...)
    local load_db = rawget(self._mo, "load_db")
    if load_db then
        self.data = load_db(self, uin, ...)

        self._hash_code = hash.hashcode(self.data or {})
    end
    self._datas = { data = self.data, mods = {}, }
    for k, v in pairs(self._mods) do
        self._datas.mods[k] = v:_loadDB(uin, ...)
    end
    return self._datas
end

function M:_saveDB(flag)
    assert(not flag, "Not support flag")
    if self._mo["save_db"] then
        self._mo["save_db"](self, self._uin, self.data)
    end
end

function M:_initalize()
    if self._mo["reg_mod"] then
        self._mo["reg_mod"](self)
    end
    for k, v in pairs(self._modclass) do
        -- 调用v()会调用模块的 __call 元方法，生成新的对象
        self._mods[k] = v(nil, self._svr)
        self._mods[k]._name = k
        self._mods[k]._parent = self
        self._mods[k]._svr = rawget(self, "_svr")
        self._mods[k]._callFunc = rawget(self, "_callFunc")
        if not self._parent then
            self._mods[k]._top = self
        else
            self._mods[k]._top = self._top
        end
        self._mods[k]:_initalize()
    end
end

function M:_connectMod()
    local func = rawget(self._mo, "connectMod")
    if func then
        func(self, uin, self.data)
    end
    for k, v in pairs(self._mods) do
        v:_connectMod()
    end
end

function M:_initData(uin, datas)
    self._uin = uin
    self.data = datas.data
    local func = rawget(self._mo, "init")
    if func then
        local ret, err = pcall(func, self, uin, self.data)
        if not ret then
            ERR("px initData error:", self._name, err, debug.traceback())
        end
    end
    for k, v in pairs(self._mods) do
        v:_initData(uin, datas.mods[k])
    end
end

function M:_delayInit()
    local func = rawget(self._mo, "delayInit")
    if func then
        func(self)
    end
    for k, v in pairs(self._mods) do
        v:_delayInit()
    end
end

-- 获取模块名列表,root模块名在array前面
function M:_getModNames()
    local names = {}
    local mod = self
    while mod._parent do
        table.insert(names, 1, mod._name)
        mod = mod._parent
    end
    return names
end

function M:_setData(mod, data)
    self._datas.mods[mod] = data
end

function M:set_data(data)
    self._datas.data = data
    rawset(self, "data", data)

    local parent = rawget(self, "_parent")
    if parent then
        parent:_setData(rawget(self, "_name"), self._datas)
    end
end

function M:get_parent()
    return self._parent
end


function M:registerModule(name, modclass)
    assert(type(modclass) == "table", name)
    assert(not self._modclass[name], name)
    self._modclass[name] = modclass
end

-- 根据缓存标志调用_saveDB 保存数据
function M:check_save()
    local nhcode = hash.hashcode(self.data or {})
    self._hash_code = self._hash_code or 0
    if self._hash_code and self._hash_code ~= nhcode then
        self._hash_code = nhcode
        self:_saveDB()
    end
    for k, v in pairs(self._mods) do
        v:check_save()
    end
end

-- 获取模块
-- 参数为table时返回 最底部的模块名,中间检查是否有空值
function M:get_module(name)
    if type(name) == "string" then
        return assert(self._mods[name], self:get_full_name() .. "." .. name)
    elseif type(name) == "table" then
        local mod = self._top or self
        for _, v in ipairs(name) do
            mod = mod:get_module(v)
        end
        return mod
    end
end

function M:get_full_name()
    local n = self:_getModNames()
    return table.concat(n, ".")
end

function M:raw_call(f, ...)
    self[f](self, ...)
    self:_rawCall(self._uin, self:_getModNames(), f, ...)
end

function M:call(mods, f, ...)
    local mod = self:get_module(mods)
    assert(mod, mods)
    return mod[f](mod, ...)
end

-- 事件注册
function M:attach(e, func, obj)
    if self._top then
        return self._top:attach(e, func, obj)
    end

    assert(e, "bad attach argument")
    assert(type(func) == "function", "bad func argument!" .. type(func))
    local con = self._events[e]
    if not con then
        con = {}
        self._events[e] = con
    end

    if obj then
        assert(type(obj) == "table", "bad obj argument!")
        con[obj] = func
    else
        con[func] = 1
    end
end

--事件取消注册
function M:detach(e, func, obj)
    if self._top then
        return self._top:detach(e, func, obj)
    end

    assert(type(e) == "string" and e ~= "", "bad detach argument")
    assert(type(func) == "function", "bad func argument!")
    local con = self._events[e]
    if not con then return end
    if obj then
        assert(type(obj) == "table", "bad obj argument!")
        con[obj] = nil
    else
        con[func] = nil
    end
end

--事件通知
function M:notify(e, ...)
    assert(e)
    if self._top then
        return self._top:notify(e, ...)
    end
    DEBUG("proxy notify :", events[e], ...)
    local con = self._events[e]
    if not con then return end
    for k, v in pairs(con) do
        if type(k) == "table" then
            v(k, ...)
        elseif type(k) == "function" then
            k(...)
        else
            assert(false, type(k))
        end
    end
end

-- 生成新对象的调用方法，如 player_px()
M.__call = function(self, svr, callFunc)
    local t = {}
    setmetatable(t, self)
    t._mo = self
    t._dtype = dtype
    t._svr = svr
    t._callFunc = callFunc
    t._mods = {}
    t._modclass = {}
    t._save_flags = {}
    t._events = {}
    t._datas = { mods = {}, }
    return t
end

local PM = {}
PM.__call = function(self, s, ...)
    local func = self._callFunc
    assert(func, "callFunc is not exist!")
    return func(self._uin, self._svr, self._mod, self._f, ...)
end

-- 对象的 __index 元方法，从 _px 模块或者 proxy_base 中取方法
local function module_index(self, f)
    return rawget(self._mo, f) or M[f]
end

-- 在模块定义中调用，生成一个新的模块，调用方法：proxy(M)
local register = function(module)
    module = module or {}
    module.__index = module_index
    setmetatable(module, M)
    return module
end

return register


