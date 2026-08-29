local mru = require("ctrlp.mru")

describe("mru", function()
	local tmp_dir
	local f1, f2, f3

	local function touch(path)
		local f = io.open(path, "w")
		f:write("x")
		f:close()
	end

	before_each(function()
		tmp_dir = vim.fn.tempname()
		vim.fn.mkdir(tmp_dir, "p")
		f1 = tmp_dir .. "/a.txt"
		f2 = tmp_dir .. "/b.txt"
		f3 = tmp_dir .. "/c.txt"
		touch(f1)
		touch(f2)
		touch(f3)
		-- 隔离真实缓存文件，避免测试读写用户数据
		mru.cache_path = tmp_dir .. "/mru_cache.txt"
		mru.clear()
	end)

	after_each(function()
		mru.clear()
		mru.cache_path = nil
		vim.fn.delete(tmp_dir, "rf")
	end)

	describe("record", function()
		it("should put the most recent file first", function()
			mru.record(f1)
			mru.record(f2)
			assert.are.same({ "b.txt", "a.txt" }, mru.list(tmp_dir))
		end)

		it("should dedupe and move re-recorded files to the front", function()
			mru.record(f1)
			mru.record(f2)
			mru.record(f1)
			assert.are.same({ "a.txt", "b.txt" }, mru.list(tmp_dir))
		end)

		it("should normalize relative paths to absolute", function()
			local prev_cwd = vim.fn.getcwd()
			vim.cmd("cd " .. vim.fn.fnameescape(tmp_dir))
			mru.record("a.txt")
			vim.cmd("cd " .. vim.fn.fnameescape(prev_cwd))
			assert.are.same({ "a.txt" }, mru.list(tmp_dir))
		end)

		it("should ignore empty paths", function()
			mru.record("")
			mru.record(nil)
			assert.are.same({}, mru.list(tmp_dir))
		end)

		it("should cap the history at max entries", function()
			mru.max = 3
			for i = 1, 5 do
				local p = tmp_dir .. "/cap" .. i .. ".txt"
				touch(p)
				mru.record(p)
			end
			mru.max = 250 -- restore

			local items = mru.list(tmp_dir)
			assert.are.equal(3, #items)
			assert.are.equal("cap5.txt", items[1])
		end)
	end)

	describe("list", function()
		it("should return paths relative to dir when inside it", function()
			mru.record(f1)
			assert.are.same({ "a.txt" }, mru.list(tmp_dir))
		end)

		it("should keep absolute paths outside dir", function()
			mru.record(f1)
			assert.are.same({ f1 }, mru.list("/somewhere/else"))
		end)

		it("should skip files that no longer exist", function()
			mru.record(f1)
			mru.record(f2)
			vim.fn.delete(f2)
			assert.are.same({ "a.txt" }, mru.list(tmp_dir))
		end)
	end)

	describe("clear", function()
		it("should empty the history", function()
			mru.record(f1)
			mru.clear()
			assert.are.same({}, mru.list(tmp_dir))
		end)
	end)

	-- 持久化：参照 ctrlp.vim 的 <cache_dir>/mru/cache.txt 机制
	describe("persistence", function()
		it("should save to and load from the cache file", function()
			mru.record(f1)
			mru.record(f2)
			mru.save()

			-- 模拟新会话：重新加载模块，从缓存文件恢复
			local cache_path = mru.cache_path
			package.loaded["ctrlp.mru"] = nil
			local mru2 = require("ctrlp.mru")
			mru2.cache_path = cache_path

			assert.are.same({ "b.txt", "a.txt" }, mru2.list(tmp_dir))

			package.loaded["ctrlp.mru"] = nil
			mru = require("ctrlp.mru")
		end)

		it("should create the cache directory if missing", function()
			mru.cache_path = tmp_dir .. "/nested/dir/mru.txt"
			mru.record(f1)
			mru.save()
			assert.are.equal(1, vim.fn.filereadable(tmp_dir .. "/nested/dir/mru.txt"))
		end)

		it("should ignore a missing cache file", function()
			mru.cache_path = tmp_dir .. "/does/not/exist.txt"
			package.loaded["ctrlp.mru"] = nil
			local mru2 = require("ctrlp.mru")
			mru2.cache_path = tmp_dir .. "/does/not/exist.txt"
			assert.are.same({}, mru2.list(tmp_dir))
			package.loaded["ctrlp.mru"] = nil
			mru = require("ctrlp.mru")
		end)
	end)
end)
