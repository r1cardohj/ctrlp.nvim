local modes = require("ctrlp.modes")

describe("modes", function()
	describe("cycle", function()
		it("should cycle forward through the mode order", function()
			assert.are.equal("buffers", modes.cycle("files", 1))
			assert.are.equal("files", modes.cycle("buffers", 1))
		end)

		it("should cycle backward through the mode order", function()
			assert.are.equal("buffers", modes.cycle("files", -1))
			assert.are.equal("files", modes.cycle("buffers", -1))
		end)

		it("should start from the first mode for unknown modes", function()
			assert.are.equal("buffers", modes.cycle("nonexistent", 1))
			assert.are.equal("buffers", modes.cycle(nil, 1))
		end)
	end)

	describe("neighbors", function()
		it("should return previous and next modes around current", function()
			local prev, next_ = modes.neighbors("files")
			assert.are.equal("buffers", prev)
			assert.are.equal("buffers", next_)

			prev, next_ = modes.neighbors("buffers")
			assert.are.equal("files", prev)
			assert.are.equal("files", next_)
		end)

		it("should fall back to the first mode for unknown modes", function()
			local prev, next_ = modes.neighbors("nonexistent")
			assert.are.equal("buffers", prev)
			assert.are.equal("buffers", next_)
		end)
	end)

	describe("buffers.collect", function()
		local tmp_dir
		local saved_bufs

		before_each(function()
			tmp_dir = vim.fn.tempname()
			vim.fn.mkdir(tmp_dir, "p")
			saved_bufs = vim.api.nvim_list_bufs()
		end)

		after_each(function()
			-- 清掉测试中打开的 buffer，避免影响其他用例
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				local known = false
				for _, b in ipairs(saved_bufs) do
					if b == buf then
						known = true
						break
					end
				end
				if not known and vim.api.nvim_buf_is_valid(buf) then
					vim.api.nvim_buf_delete(buf, { force = true })
				end
			end
			vim.fn.delete(tmp_dir, "rf")
		end)

		it("should collect listed buffers relative to dir when possible", function()
			-- dir 内的文件
			local inside = io.open(tmp_dir .. "/inside.txt", "w")
			inside:write("i")
			inside:close()
			-- dir 外的文件
			local outside = io.open(tmp_dir .. "_outside.txt", "w")
			outside:write("o")
			outside:close()

			vim.cmd("edit " .. vim.fn.fnameescape(tmp_dir .. "/inside.txt"))
			vim.cmd("edit " .. vim.fn.fnameescape(tmp_dir .. "_outside.txt"))

			local items = modes.modes.buffers.collect(tmp_dir, {})
			local set = {}
			for _, item in ipairs(items) do
				set[item] = true
			end

			assert.is_true(set["inside.txt"], "expected relative path for buffer inside dir")
			assert.is_true(
				set[vim.fn.fnamemodify(tmp_dir .. "_outside.txt", ":p")],
				"expected absolute path for buffer outside dir"
			)

			vim.fn.delete(tmp_dir .. "_outside.txt")
		end)

		it("should skip unlisted and unnamed buffers", function()
			local items = modes.modes.buffers.collect(tmp_dir, {})
			for _, item in ipairs(items) do
				assert.is_true(item ~= "", "empty buffer name should be skipped")
			end
		end)
	end)
end)
