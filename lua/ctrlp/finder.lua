local M = {}

function M.scan(dir, config)
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
	return files
end

return M
