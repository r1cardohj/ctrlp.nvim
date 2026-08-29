-- 回归测试：结果面板需要跟随选中项自动滚动（issue: 结果区不可滚动 / 不自动滚动）
--
-- 说明：headless 模式下无法真正进入 Insert 模式，因此这里直接调用
-- prompt buffer 上注册的 <C-n>/<C-p> keymap 回调来驱动导航。
local ui = require("ctrlp.ui")
local modes = require("ctrlp.modes")

describe("ui result panel scrolling", function()
	local orig_files_collect

	before_each(function()
		orig_files_collect = modes.modes.files.collect
	end)

	after_each(function()
		modes.modes.files.collect = orig_files_collect
	end)

	local function open_ui(n)
		local files = {}
		for i = 1, n do
			table.insert(files, string.format("file%03d.lua", i))
		end
		modes.modes.files.collect = function()
			return files
		end
		ui.open({}, ".")
	end

	-- 找到 ctrlp 的两个浮动窗口：结果窗口与 prompt 窗口（用于拿 keymap 回调）
	local function find_windows()
		local result_win, prompt_buf
		for _, w in ipairs(vim.api.nvim_list_wins()) do
			local cfg = vim.api.nvim_win_get_config(w)
			if cfg.relative == "editor" then
				local buf = vim.api.nvim_win_get_buf(w)
				if vim.bo[buf].buftype == "prompt" then
					prompt_buf = buf
				else
					result_win = w
				end
			end
		end
		return result_win, prompt_buf
	end

	local function keymap_callback(buf, lhs)
		for _, km in ipairs(vim.api.nvim_buf_get_keymap(buf, "i")) do
			if km.lhs == lhs and km.callback then
				return km.callback
			end
		end
	end

	local function close_ui(result_win, prompt_buf)
		-- 关闭 prompt 窗口会触发 ui.close() 连带关闭结果窗口，
		-- 因此每次都要先校验窗口是否仍有效。
		for _, w in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_is_valid(w)
				and vim.api.nvim_win_get_config(w).relative == "editor" then
				vim.api.nvim_win_close(w, true)
			end
		end
		if result_win and vim.api.nvim_win_is_valid(result_win) then
			local result_buf = vim.api.nvim_win_get_buf(result_win)
			if vim.api.nvim_buf_is_valid(result_buf) then
				vim.api.nvim_buf_delete(result_buf, { force = true })
			end
		end
		if prompt_buf and vim.api.nvim_buf_is_valid(prompt_buf) then
			vim.api.nvim_buf_delete(prompt_buf, { force = true })
		end
	end

	it("scrolls the result panel to keep the selected item visible", function()
		open_ui(60)

		local result_win, prompt_buf = find_windows()
		assert(result_win, "result window not found")
		assert(prompt_buf, "prompt buffer not found")

		local height = vim.api.nvim_win_get_height(result_win)
		local ctrl_n = keymap_callback(prompt_buf, "<C-N>")
		local ctrl_p = keymap_callback(prompt_buf, "<C-P>")
		assert(ctrl_n and ctrl_p, "navigation keymaps not found")

		local function top_line()
			return vim.api.nvim_win_call(result_win, function()
				return vim.fn.line("w0")
			end)
		end

		local function selected_line()
			local lines = vim.api.nvim_buf_get_lines(
				vim.api.nvim_win_get_buf(result_win), 0, -1, false)
			for i, l in ipairs(lines) do
				if l:sub(1, 2) == "> " then
					return i
				end
			end
		end

		assert.equal(1, top_line())
		assert.equal(1, selected_line())

		-- 向下移动到可视区域之外，面板应向下滚动保持选中项可见
		for _ = 1, height + 5 do
			ctrl_n()
		end
		local sel = selected_line()
		local top = top_line()
		assert.is_true(top > 1, "result panel did not scroll down")
		assert.is_true(
			sel >= top and sel <= top + height - 1,
			string.format("selected item %d is outside visible range %d..%d",
				sel, top, top + height - 1)
		)

		-- 向上移动回顶部，面板应滚回第一行
		for _ = 1, height + 5 do
			ctrl_p()
		end
		assert.equal(1, selected_line())
		assert.equal(1, top_line())

		close_ui(result_win, prompt_buf)
	end)

	-- 回归测试：pwd 在子目录、扫描根在上级目录时，打开文件应相对扫描根
	-- 解析（参照 ctrlp.vim 用缓存根路径拼接条目），而不是相对 pwd。
	it("opens the selected file relative to the scan root, not the cwd", function()
		-- root/real_file.txt 存在；root/sub 是 pwd，下面并没有该文件
		local root = vim.fn.tempname()
		vim.fn.mkdir(root .. "/sub", "p")
		local f = io.open(root .. "/real_file.txt", "w")
		f:write("hello")
		f:close()

		local prev_cwd = vim.fn.getcwd()
		vim.cmd("cd " .. vim.fn.fnameescape(root .. "/sub"))

		modes.modes.files.collect = function()
			return { "real_file.txt" }
		end
		ui.open({}, root)
		local _, prompt_buf = find_windows()
		local cr = keymap_callback(prompt_buf, "<CR>")
		assert(cr, "<CR> keymap not found")
		cr()

		assert.equal(root .. "/real_file.txt", vim.api.nvim_buf_get_name(0))

		-- cleanup
		vim.cmd("bwipeout!")
		vim.cmd("cd " .. vim.fn.fnameescape(prev_cwd))
		vim.fn.delete(root, "rf")
	end)
end)

-- 模式切换：<C-f>/<C-b> 在不关闭窗口的情况下切换 files/buffers 模式
describe("ui mode switching", function()
	local orig_buffers_collect
	local orig_files_collect
	local orig_mru_collect

	before_each(function()
		orig_buffers_collect = modes.modes.buffers.collect
		orig_files_collect = modes.modes.files.collect
		orig_mru_collect = modes.modes.mru.collect
		modes.modes.buffers.collect = function()
			return { "buffer_a.txt", "buffer_b.txt" }
		end
		modes.modes.files.collect = function()
			return { "fake_file.lua" }
		end
		modes.modes.mru.collect = function()
			return { "mru_recent.txt" }
		end
	end)

	after_each(function()
		modes.modes.buffers.collect = orig_buffers_collect
		modes.modes.files.collect = orig_files_collect
		modes.modes.mru.collect = orig_mru_collect
		for _, w in ipairs(vim.api.nvim_list_wins()) do
			if vim.api.nvim_win_is_valid(w)
				and vim.api.nvim_win_get_config(w).relative == "editor" then
				vim.api.nvim_win_close(w, true)
			end
		end
	end)

	local function result_lines()
		for _, w in ipairs(vim.api.nvim_list_wins()) do
			local cfg = vim.api.nvim_win_get_config(w)
			if cfg.relative == "editor" then
				local buf = vim.api.nvim_win_get_buf(w)
				if vim.bo[buf].buftype ~= "prompt" then
					return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
				end
			end
		end
	end

	local function keymap_callback(lhs)
		for _, w in ipairs(vim.api.nvim_list_wins()) do
			local buf = vim.api.nvim_win_get_buf(w)
			if vim.api.nvim_win_get_config(w).relative == "editor"
				and vim.bo[buf].buftype == "prompt" then
				for _, km in ipairs(vim.api.nvim_buf_get_keymap(buf, "i")) do
					if km.lhs == lhs and km.callback then
						return km.callback
					end
				end
			end
		end
	end

	local function has_line(lines, text)
		for _, l in ipairs(lines or {}) do
			if l:find(text, 1, true) then
				return true
			end
		end
		return false
	end

	it("switches from files to buffers with <C-f> and back with <C-b>", function()
		ui.open({}, ".")

		local ctrl_f = keymap_callback("<C-F>")
		local ctrl_b = keymap_callback("<C-B>")
		assert(ctrl_f and ctrl_b, "mode switching keymaps not found")

		-- 初始为 files 模式
		assert.is_true(has_line(result_lines(), "fake_file.lua"))

		-- 切到 buffers 模式，条目重新收集
		ctrl_f()
		local lines = result_lines()
		assert.is_true(has_line(lines, "buffer_a.txt"))
		assert.is_true(has_line(lines, "buffer_b.txt"))
		assert.is_falsy(has_line(lines, "fake_file.lua"))

		-- 再切到 mru 模式
		ctrl_f()
		assert.is_true(has_line(result_lines(), "mru_recent.txt"))

		-- 切回 buffers，再切回 files
		ctrl_b()
		assert.is_true(has_line(result_lines(), "buffer_a.txt"))
		ctrl_b()
		assert.is_true(has_line(result_lines(), "fake_file.lua"))
	end)

	it("opens buffers mode directly when mode is given", function()
		ui.open({}, ".", "buffers")
		assert.is_true(has_line(result_lines(), "buffer_a.txt"))
		assert.is_falsy(has_line(result_lines(), "fake_file.lua"))
	end)

	local function prompt_title()
		for _, w in ipairs(vim.api.nvim_list_wins()) do
			local buf = vim.api.nvim_win_get_buf(w)
			if vim.api.nvim_win_get_config(w).relative == "editor"
				and vim.bo[buf].buftype == "prompt" then
				return vim.api.nvim_win_get_config(w).title
			end
		end
	end

	it("shows adjacent modes around the current mode on the prompt window", function()
		local function title_segments()
			local t = prompt_title()
			local texts = {}
			for _, seg in ipairs(t) do
				table.insert(texts, seg[1])
			end
			return table.concat(texts), t
		end

		-- 形如 " MRU < Files > Buffers "，当前模式高亮
		ui.open({}, ".")
		local text, segments = title_segments()
		assert.are.equal(" MRU < Files > Buffers ", text)
		assert.are.equal("CtrlPModeCurrent", segments[4][2])
		assert.are.equal("CtrlPModeAdjacent", segments[2][2])

		keymap_callback("<C-F>")()
		text = title_segments()
		assert.are.equal(" Files < Buffers > MRU ", text)
	end)
end)
