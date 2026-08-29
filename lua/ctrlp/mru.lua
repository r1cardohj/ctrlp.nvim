local M = {}

--- Most recently used files, most recent first. Stores absolute paths.
--- Like ctrlp.vim, the list is persisted to a cache file: loaded lazily
--- on first access, saved on VimLeavePre (wired up in init.lua).
--- nil means "not loaded from disk yet".
local history = nil

--- Maximum number of entries kept (ctrlp.vim: g:ctrlp_mruf_max).
M.max = 250

--- Cache file path. nil = use the default under stdpath("cache"),
--- mirroring ctrlp.vim's <cache_dir>/mru/cache.txt.
M.cache_path = nil

local function cache_path()
	return M.cache_path or (vim.fn.stdpath("cache") .. "/ctrlp/mru.txt")
end

local function ensure_loaded()
	if history then
		return
	end
	history = {}
	local f = io.open(cache_path(), "r")
	if not f then
		return
	end
	for line in f:lines() do
		if line ~= "" then
			table.insert(history, line)
		end
	end
	f:close()
	while #history > M.max do
		table.remove(history)
	end
end

--- Persist the history to the cache file.
function M.save()
	ensure_loaded()
	local path = cache_path()
	vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
	local f = io.open(path, "w")
	if not f then
		return
	end
	for _, p in ipairs(history) do
		f:write(p .. "\n")
	end
	f:close()
end

local function normalize(path)
	return vim.fn.fnamemodify(path, ":p")
end

--- Record a file access, moving it to the front of the history.
function M.record(path)
	if not path or path == "" then
		return
	end
	ensure_loaded()
	local abs = normalize(path)

	for i, p in ipairs(history) do
		if p == abs then
			table.remove(history, i)
			break
		end
	end

	table.insert(history, 1, abs)

	while #history > M.max do
		table.remove(history)
	end
end

--- Return the MRU list, most recent first. Files that no longer exist are
--- skipped. Paths inside `dir` are returned relative to it, matching how
--- the other modes present their items.
function M.list(dir)
	ensure_loaded()
	local items = {}
	for _, p in ipairs(history) do
		if vim.fn.filereadable(p) == 1 then
			local item = p
			if dir and p:sub(1, #dir + 1) == dir .. "/" then
				item = p:sub(#dir + 2)
			end
			table.insert(items, item)
		end
	end
	return items
end

function M.clear()
	ensure_loaded()
	history = {}
end

return M
