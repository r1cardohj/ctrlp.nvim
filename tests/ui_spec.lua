-- 回归测试：结果面板需要跟随选中项自动滚动（issue: 结果区不可滚动 / 不自动滚动）
--
-- 说明：headless 模式下无法真正进入 Insert 模式，因此这里直接调用
-- prompt buffer 上注册的 <C-n>/<C-p> keymap 回调来驱动导航。
local ui = require("ctrlp.ui")

describe("ui result panel scrolling", function()
	local function open_ui(n)
		local files = {}
		for i = 1, n do
			table.insert(files, string.format("file%03d.lua", i))
		end
		ui.open(files, {}, ".")
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
end)
