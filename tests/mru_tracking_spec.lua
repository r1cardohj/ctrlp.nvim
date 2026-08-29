-- 集成测试：BufEnter autocmd 应自动记录普通文件 buffer。
-- 注：plenary busted 环境会重置 plugin/ 加载时注册的 autocmd，
-- 因此这里显式调用 setup_mru_tracking()（与 plugin/ctrlp.lua 相同的入口）。
local mru = require("ctrlp.mru")

describe("mru BufEnter tracking", function()
	local tmp_dir

	before_each(function()
		tmp_dir = vim.fn.tempname()
		vim.fn.mkdir(tmp_dir, "p")
		mru.cache_path = tmp_dir .. "/mru_cache.txt"
		mru.clear()
		require("ctrlp").setup_mru_tracking()
	end)

	after_each(function()
		mru.clear()
		mru.cache_path = nil
		vim.cmd("bwipeout!")
		vim.fn.delete(tmp_dir, "rf")
	end)

	it("should record normal file buffers on BufEnter", function()
		local f = io.open(tmp_dir .. "/tracked.txt", "w")
		f:write("x")
		f:close()

		vim.cmd("edit " .. vim.fn.fnameescape(tmp_dir .. "/tracked.txt"))

		local items = mru.list(tmp_dir)
		assert.are.same({ "tracked.txt" }, items)
	end)

	it("should not record unnamed buffers", function()
		vim.cmd("enew")
		assert.are.same({}, mru.list(tmp_dir))
	end)
end)
