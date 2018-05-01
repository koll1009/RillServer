local lfs = require "lfs"

local M = {}


local sep = string.match (package.config, "[^\n]+")
function M.attrdir(path, cb)
	local ret = {}
    for file in lfs.dir(path) do
        if string.sub(file, 1, 1) ~= "." then
            local f = path .. sep .. file
            table.insert(ret, f)
			if type(cb) == "function" then cb(f) end
            local attr = lfs.attributes(f)
            assert(type(attr) == "table")
            if attr.mode == "directory" then
                M.attrdir(f, cb)
            else
                --for name, value in pairs(attr) do
                --    print(name, value)
                --end
            end
        end
    end
	return ret
end

return M

