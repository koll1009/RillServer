local reload = {}


local table = table
local debug = debug

local sandbox = {}
local sandbox_meta = {}
local sandbox_mods = {}


local function make_sandbox()
    return setmetatable({}, sandbox)
end
local function empty_func()
end
local function sandbox_pairs()
    return empty_func
end
local function sandbox_setmetatable(t, meta)
    sandbox_meta[t] = meta
    return t
end
local function sandbox_require(mod)
    if not sandbox_mods[mod] then
        sandbox_mods[mod] = make_sandbox()
    end
    return sandbox_mods[mod]
end

sandbox.__index = function(t, k)
    if k == "setmetatable" then
        return sandbox_setmetatable
    elseif k == "pairs" or k == "ipairs" then
        return sandbox_pairs
    elseif k == "next" then
        return empty_func
    elseif k == "require" then
        return sandbox_require
    else
        local sandbox_table = make_sandbox()
        rawset(t, k, sandbox_table)
        return sandbox_table
    end
end

sandbox.__newindex = function(t, k, v)
    rawset(t, k, v)
end

sandbox.__call = function()
    return make_sandbox(), make_sandbox(), make_sandbox()
end

sandbox.__add = function()
    sandbox.__call()
end

sandbox.__sub = function()
    sandbox.__call()
end

sandbox.__mul = function()
    sandbox.__call()
end

sandbox.__div = function()
    sandbox.__call()
end

sandbox.__mod = function()
    sandbox.__call()
end

sandbox.__pow = function()
    sandbox.__call()
end

sandbox.__num = function()
    sandbox.__call()
end

sandbox.__concat = function()
    sandbox.__call()
end

sandbox.__eq = function()
    sandbox.__call()
end

sandbox.__lt = function()
    sandbox.__call()
end

sandbox.__le = function()
    sandbox.__call()
end

sandbox.__len = function()
    sandbox.__call()
end


local protection = {
    setmetatable = true,
    pairs = true,
    ipairs = true,
    next = true,
    require = true,
    _ENV = true,
    reload = true,
}

local change_func = nil
local visited_sig = nil
local update_obj
local update_function
local update_table
local update_upvalue

function update_upvalue(old_func, new_func, name, deep)
    local old_upvalue = {}
    local old_exist_name = {}
    for i = 1, math.huge do
        local name, value = debug.getupvalue(old_func, i)
        if not name then break end
        old_upvalue[name] = value
        old_exist_name[name] = true
    end
    for i = 1, math.huge do
        local name, value = debug.getupvalue(new_func, i)
        if not name then break end

        if name == "_ENV" then
            debug.setupvalue(new_func, i, _ENV)
        else
            if old_exist_name[name] then
                local old_value = old_upvalue[name]
                if type(old_value) ~= type(value) then
                    debug.setupvalue(new_func, i, old_value)
                elseif type(old_value) == "function" then
                    update_function(old_value, value, name, deep .. " ")
                elseif type(old_value) == "table" then
                    update_table(old_value, value, name, deep .. " ")
                    debug.setupvalue(new_func, i, old_value)
                else
                    debug.setupvalue(new_func, i, old_value)
                end
            end
        end
    end
end

function update_function(old_func, new_func, name, deep)
    if protection[old_func] or protection[new_func] then return end
    if old_func == new_func then return end
    local signature = tostring(old_func) .. tostring(new_func)
    if visited_sig[signature] then return end
    visited_sig[signature] = true
    update_upvalue(old_func, new_func, name, deep)
	
    change_func[old_func] = new_func
end

function update_table(old_table, new_table, name, deep)


    if protection[old_table] or protection[new_table] then return end
    if old_table == new_table then return end

    local signature = tostring(old_table) .. tostring(new_table)
    if visited_sig[signature] then return end
    visited_sig[signature] = true


    for name, value in pairs(new_table) do
        local old_value = old_table[name]
        if type(value) == type(old_value) then
            if type(value) == "function" then
                update_function(old_value, value, name, deep .. " ")
            elseif type(value) == "table" then
                update_table(old_value, value, name, deep .. " ")
            end
        elseif old_value == nil and type(value) == "function" then
            local env, uv = debug.getupvalue(value, 1)
            if env == "_ENV" then
                debug.setupvalue(value, 1, _ENV)
            end
            old_table[name] = value
        end
    end

    local old_meta = debug.getmetatable(old_table)
    local new_meta = sandbox_meta[new_table]
    if type(old_meta) == "table" and type(new_meta) == "table" then
        update_table(old_meta, new_meta, "Meta", deep .. " ")
    end
end

function update_obj(old_obj, new_obj, name, deep)
    if type(old_obj) == type(new_obj) then
        if type(old_obj) == "table" then
            update_table(old_obj, new_obj, name, deep)
        elseif type(old_obj) == "function" then
            update_function(old_obj, new_obj, name, deep)
        end
    end
end

local function findcode(mod)
    local filename = package.searchpath(mod, package.path)
    if not filename then
        return false
    end
    local fp = io.open(filename, "r")
    if not fp then
        return false
    end
    io.input(fp)
    local code = io.read("*all")
    io.close(fp)
    return true, code
end

local function loadmod(mod, env)
    local ret, code = findcode(mod)
    if not ret then
        return false
    end
    if not env then
        env = _ENV
    end
    local f, err = load(code, mod, "bt", env)
    if not f then
        return false, err
    end

    local obj = nil
    xpcall(
        function()
            obj = f()
        end,
        function()
            debug.traceback()
        end
    )
    return true, f, obj
end


local function travel_all()
    local visited = {}
    visited.reload = true
    local function f(t)
        if type(t) ~= "function" and type(t) ~= "table" then return end
        if visited[t] then return end
        if protection[t] then return end
        visited[t] = true

        if type(t) == "function" then
            for i = 1, math.huge do
                local name, value = debug.getupvalue(t, i)
                if not name then break end
                f(value)
            end
        elseif type(t) == "table" then
		
            f(debug.getmetatable(t))
            for k, v in pairs(t) do
                f(k)
                f(v)
                if type(v) == "function" then
					if get == 3 then print("change_func:"..k) end  --测试
                    if change_func[v] then
                        t[k] = change_func[v]
                    end
                end
                if type(k) == "fuction" then
                    if change_func[k] then
                        t[change_func[k]] = t[k]
                        t[k] = nil
                    end
                end
            end
        end
    end

    f(_G)
    local reg = debug.getregistry()
    for old_func, new_func in pairs(change_func) do
        for k, v in pairs(reg) do
            if v == old_func then
                reg[k] = new_func
            end
        end
    end
end

local function init()
    change_func = {}
    visited_sig = {}
end


function reload.loadmod(mod)
    local ret, func, obj = loadmod(mod, _ENV)
    if not ret then
        return false, "load mod false"
    end
    return obj
end



function reload.reload(mod)
    init()

    local old_obj = package.loaded[mod]
    if not old_obj then
        return false, "mod not found"
    end
    local env = make_sandbox()
    local ret, func, new_obj = loadmod(mod, env)
    if not ret then
        return false, "load mod false"
    end

    update_obj(old_obj, new_obj, "reload", "")
    for name, value in pairs(sandbox_mods) do
        local old_value = package.loaded[name]
        update_obj(old_value, value, name, "")
    end

    setmetatable(env, nil)
    update_obj(_ENV, env, "ENV", "")
    travel_all()
	
	debug.setupvalue(func, 1, _ENV)
	func()
    return true
end

return reload


