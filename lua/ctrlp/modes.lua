local M = {}

--- Mode registry.
---
--- Each mode is a table with:
---   name:    string, display name shown in the UI
---   collect: fun(dir:string, config:table):string[]
---            returns the item list for that mode. Items are paths relative
---            to `dir` when possible, absolute paths otherwise.
M.modes = {
	files = {
		name = "Files",
		collect = function(dir, config)
			return require("ctrlp.finder").scan(dir, config)
		end,
	},
	buffers = {
		name = "Buffers",
		collect = function(dir, _)
			local items = {}
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if vim.bo[buf].buflisted then
					local name = vim.api.nvim_buf_get_name(buf)
					if name ~= "" then
						-- Prefer paths relative to the scan root, keep
						-- absolute paths for buffers outside of it.
						local item = name
						if name:sub(1, #dir + 1) == dir .. "/" then
							item = name:sub(#dir + 2)
						end
						table.insert(items, item)
					end
				end
			end
			table.sort(items)
			return items
		end,
	},
}

--- Cycling order of modes for <C-f> / <C-b>.
M.order = { "files", "buffers" }

--- Return the mode key after moving `delta` steps from `current`.
--- Unknown modes are treated as the first entry.
function M.cycle(current, delta)
	local idx = 1
	for i, key in ipairs(M.order) do
		if key == current then
			idx = i
			break
		end
	end
	return M.order[((idx - 1 + delta) % #M.order) + 1]
end

return M
