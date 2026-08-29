local M = {}

local cache = {}

--- Walk up from `start_dir` looking for any of the given root markers
--- (e.g. ".git", "package.json", "go.mod"). Returns the directory
--- containing the first marker found, or `start_dir` if none is found.
function M.find_root(start_dir, markers)
	if not markers or #markers == 0 then
		return start_dir
	end
	local found = vim.fs.find(markers, { path = start_dir, upward = true })[1]
	if found then
		return vim.fs.dirname(found)
	end
	return start_dir
end

function M.scan(dir, config)
	local real_dir = vim.loop.fs_realpath(dir) or dir

	if config.use_cache ~= false and cache[real_dir] then
		return cache[real_dir]
	end

	local files = {}
	local count = 0
	local visited = {}

	local function should_ignore(path)
		for _, pattern in ipairs(config.ignore_patterns or {}) do
			if path:match(pattern) then
				return true
			end
		end
		return false
	end

	local function scan_recursive(current)
		local real = vim.loop.fs_realpath(current) or current
		if visited[real] then
			return
		end
		visited[real] = true

		local handle = vim.loop.fs_scandir(current)
		if not handle then
			return
		end

		while true do
			if count >= config.max_files then
				break
			end

			local name, t = vim.loop.fs_scandir_next(handle)
			if not name then
				break
			end

			local full = current .. "/" .. name
			local rel = full:sub(#dir + 2)

			if should_ignore(rel) then
				goto continue
			end

			if t == "directory" then
				scan_recursive(full)
			elseif t == "file" then
				count = count + 1
				table.insert(files, rel)
			end

			::continue::
		end
	end

	scan_recursive(dir)

	if config.use_cache ~= false then
		cache[real_dir] = files
	end

	return files
end

function M.clear_cache()
	cache = {}
end

return M
