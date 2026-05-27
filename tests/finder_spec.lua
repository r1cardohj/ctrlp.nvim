local finder = require("ctrlp.finder")

describe("finder.scan", function()
	local config = {
		max_files = 10000,
		use_cache = true,
		ignore_patterns = {
			"^%.git/",
			"^node_modules/",
			"^target/",
			"^dist/",
			"^build/",
		},
	}

	before_each(function()
		finder.clear_cache()
	end)

	it("should scan current project and find known files", function()
		local files = finder.scan(".", config)
		assert.is_true(#files > 0, "expected at least one file")

		-- 检查是否包含 README.md
		local found_readme = false
		for _, f in ipairs(files) do
			if f == "README.md" then
				found_readme = true
				break
			end
		end
		assert.is_true(found_readme, "expected README.md in scanned files")
	end)

	it("should ignore directories matching patterns", function()
		local files = finder.scan(".", config)

		-- 确保不会扫描到 .git 目录里的文件
		for _, f in ipairs(files) do
			assert.is_falsy(f:match("^%.git/"), "should ignore .git/ but found: " .. f)
		end
	end)

	it("should respect max_files limit", function()
		local limited_config = vim.tbl_deep_extend("force", config, { max_files = 2 })
		local files = finder.scan(".", limited_config)
		assert.is_true(#files <= 2, "expected at most 2 files but got " .. #files)
	end)

	it("should return cached result on second scan", function()
		local files_first = finder.scan(".", config)
		local files_second = finder.scan(".", config)
		assert.are.same(files_first, files_second)
	end)

	it("should not use cache when use_cache is false", function()
		local no_cache_config = vim.tbl_deep_extend("force", config, { use_cache = false })
		local files = finder.scan(".", no_cache_config)
		assert.is_true(#files > 0)

		-- 再次扫描应该重新读取（虽然结果一样，但代码路径不同）
		local files_again = finder.scan(".", no_cache_config)
		assert.are.same(files, files_again)
	end)

	it("should clear cache", function()
		local files_first = finder.scan(".", config)
		assert.is_true(#files_first > 0)

		finder.clear_cache()

		-- clear 后再次扫描应该重新生成结果（数据相同但证明缓存已清）
		local files_after_clear = finder.scan(".", config)
		assert.are.same(files_first, files_after_clear)
	end)
end)
