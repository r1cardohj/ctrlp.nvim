local finder = require("ctrlp.finder")

describe("finder.scan", function()
	local config = {
		max_files = 10000,
		ignore_patterns = {
			"^%.git/",
			"^node_modules/",
			"^target/",
			"^dist/",
			"^build/",
		},
	}

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
end)
