local M = {}

local matcher = require("ctrlp.matcher")
local modes = require("ctrlp.modes")

local ns = vim.api.nvim_create_namespace("ctrlp")

local state = {
	buf = nil,
	win = nil,
	prompt_buf = nil,
	prompt_win = nil,
	items = {},
	results = {},
	selected = 1,
	query = "",
	config = {},
	dir = nil,
	mode = "files",
}

local function close()
	if state.prompt_win and vim.api.nvim_win_is_valid(state.prompt_win) then
		vim.api.nvim_win_close(state.prompt_win, true)
	end
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
	end
	if state.prompt_buf and vim.api.nvim_buf_is_valid(state.prompt_buf) then
		vim.api.nvim_buf_delete(state.prompt_buf, { force = true })
	end
	if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
		vim.api.nvim_buf_delete(state.buf, { force = true })
	end
	state.win = nil
	state.buf = nil
	state.prompt_win = nil
	state.prompt_buf = nil
end

local function render_results()
	local lines = {}
	for i, item in ipairs(state.results) do
		local prefix = (i == state.selected) and "> " or "  "
		table.insert(lines, prefix .. item)
	end

	if #state.results == 0 then
		table.insert(lines, "  (no matches)")
	end

	vim.api.nvim_buf_set_option(state.buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(state.buf, "modifiable", false)

	vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
	if state.results[state.selected] then
		vim.api.nvim_buf_set_extmark(state.buf, ns, state.selected - 1, 0, {
			end_line = state.selected,
			hl_group = "CtrlPSelected",
			hl_eol = true,
			priority = 100,
		})
	end

	-- Highlight the characters matched by the query in each result line,
	-- like ctrlp.vim's CtrlPMatch. Above the selection highlight so matched
	-- chars stay visible on the selected line.
	if state.query ~= "" then
		local query = state.query:lower()
		for i, item in ipairs(state.results) do
			local positions = matcher.match_positions(item, query)
			for _, pos in ipairs(positions or {}) do
				-- line text is "  " / "> " (2 bytes) .. item
				vim.api.nvim_buf_set_extmark(state.buf, ns, i - 1, pos + 1, {
					end_col = pos + 2,
					hl_group = "CtrlPMatch",
					priority = 110,
				})
			end
		end
	end

	-- Keep the selected item visible: move the window cursor to the selected
	-- line so the floating window scrolls to follow it.
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_set_cursor(state.win, { state.selected, 0 })
	end
end

local function update_results()
	state.results = matcher.fuzzy_match(state.items, state.query)
	state.selected = 1
	render_results()
end

--- Re-collect the item list for the current mode (used on mode switch and
--- on manual refresh).
local function refresh_items()
	state.items = modes.modes[state.mode].collect(state.dir, state.config)
end

--- Prompt title showing adjacent modes around the current one, like
--- ctrlp.vim's statusline: "prev < current > next".
local function mode_title()
	local prev, next_ = modes.neighbors(state.mode)
	return {
		{ " " },
		{ modes.modes[prev].name, "CtrlPModeAdjacent" },
		{ " < " },
		{ modes.modes[state.mode].name, "CtrlPModeCurrent" },
		{ " > " },
		{ modes.modes[next_].name, "CtrlPModeAdjacent" },
		{ " " },
	}
end

--- Show the current mode name on the prompt window's border.
local function update_mode_display()
	if state.prompt_win and vim.api.nvim_win_is_valid(state.prompt_win) then
		local cfg = vim.api.nvim_win_get_config(state.prompt_win)
		cfg.title = mode_title()
		vim.api.nvim_win_set_config(state.prompt_win, cfg)
	end
end

--- Switch to the next/previous mode without closing the window.
--- The typed query is kept, like in ctrlp.vim.
local function switch_mode(delta)
	state.mode = modes.cycle(state.mode, delta)
	refresh_items()
	update_results()
	update_mode_display()
end

local function open_file()
	local item = state.results[state.selected]
	if not item then
		return
	end
	-- Results are relative to the scan root (state.dir), which may differ
	-- from the pwd when root detection kicked in. Like ctrlp.vim, resolve
	-- the selected file against the root, not the current directory.
	-- Buffer-mode items outside the root are already absolute.
	local path = item
	if item:sub(1, 1) ~= "/" then
		path = state.dir .. "/" .. item
	end
	close()
	vim.cmd("edit " .. vim.fn.fnameescape(path))
end

local function move_selection(delta)
	if #state.results == 0 then
		return
	end
	state.selected = state.selected + delta
	if state.selected < 1 then
		state.selected = 1
	elseif state.selected > #state.results then
		state.selected = #state.results
	end
	render_results()
end

function M.open(config, dir, mode)
	state.mode = mode or "files"
	state.config = config
	state.dir = dir
	state.query = ""
	state.selected = 1
	state.results = {}
	refresh_items()

	local width = math.floor(vim.o.columns * 0.6)
	local height = math.floor(vim.o.lines * 0.4) - 1
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	state.buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(state.buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(state.buf, "swapfile", false)
	vim.api.nvim_buf_set_option(state.buf, "bufhidden", "wipe")

	state.win = vim.api.nvim_open_win(state.buf, false, {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row + 3,
		style = "minimal",
		border = "rounded",
		title = " CtrlP ",
		title_pos = "center",
	})

	state.prompt_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(state.prompt_buf, "buftype", "prompt")
	vim.fn.prompt_setcallback(state.prompt_buf, function() end)
	vim.fn.prompt_setprompt(state.prompt_buf, "")

	state.prompt_win = vim.api.nvim_open_win(state.prompt_buf, true, {
		relative = "editor",
		width = width,
		height = 1,
		col = col,
		row = row,
		style = "minimal",
		border = "rounded",
		title = mode_title(),
		title_pos = "center",
	})

	vim.api.nvim_win_set_option(state.prompt_win, "winhl", "Normal:Normal")
	-- Cursor is used to drive scrolling; blend it into the selected line so it
	-- is not visible as a block cursor.
	vim.api.nvim_win_set_option(state.win, "winhl", "Normal:Normal,CursorLine:CtrlPSelected,Cursor:CtrlPSelected")
	vim.api.nvim_win_set_option(state.win, "cursorline", false)
	vim.api.nvim_win_set_option(state.win, "scrolloff", 0)

	vim.api.nvim_set_hl(0, "CtrlPSelected", { link = "PmenuSel", default = true })
	vim.api.nvim_set_hl(0, "CtrlPModeCurrent", { link = "Title", default = true })
	vim.api.nvim_set_hl(0, "CtrlPModeAdjacent", { link = "Comment", default = true })
	vim.api.nvim_set_hl(0, "CtrlPMatch", { link = "Special", default = true })

	update_results()

	local opts = { buffer = state.prompt_buf }
	vim.keymap.set("i", "<CR>", function()
		open_file()
	end, opts)
	vim.keymap.set("i", "<C-c>", close, opts)
	vim.keymap.set("i", "<Esc>", close, opts)
	vim.keymap.set("i", "<C-n>", function()
		move_selection(1)
	end, opts)
	vim.keymap.set("i", "<C-p>", function()
		move_selection(-1)
	end, opts)
	-- <C-j>/<C-k> would insert a newline in the prompt buffer; a newline can
	-- never match a file path, so use them for selection movement instead
	-- (mirrors the original ctrlp).
	vim.keymap.set("i", "<C-j>", function()
		move_selection(1)
	end, opts)
	vim.keymap.set("i", "<C-k>", function()
		move_selection(-1)
	end, opts)
	vim.keymap.set("i", "<Down>", function()
		move_selection(1)
	end, opts)
	vim.keymap.set("i", "<Up>", function()
		move_selection(-1)
	end, opts)
	vim.keymap.set("i", "<F5>", function()
		require("ctrlp.finder").clear_cache()
		refresh_items()
		update_results()
	end, opts)
	vim.keymap.set("i", "<C-f>", function()
		switch_mode(1)
	end, opts)
	vim.keymap.set("i", "<C-b>", function()
		switch_mode(-1)
	end, opts)

	vim.api.nvim_create_autocmd("TextChangedI", {
		buffer = state.prompt_buf,
		callback = function()
			local lines = vim.api.nvim_buf_get_lines(state.prompt_buf, 0, -1, false)
			local text = table.concat(lines, "")
			state.query = text
			update_results()
		end,
	})

	vim.api.nvim_create_autocmd({ "BufLeave", "BufWipeout" }, {
		buffer = state.prompt_buf,
		callback = close,
		once = true,
	})

	vim.cmd("startinsert!")
end

return M
