local finder = require("ctrlp.finder")

describe("finder.find_root", function()
	local tmp_root

	before_each(function()
		-- tmp/project/.git
		-- tmp/project/sub/deep
		tmp_root = vim.fn.tempname()
		vim.fn.mkdir(tmp_root .. "/project/.git", "p")
		vim.fn.mkdir(tmp_root .. "/project/sub/deep", "p")
	end)

	after_each(function()
		vim.fn.delete(tmp_root, "rf")
	end)

	it("should detect project root from a nested directory", function()
		local root = finder.find_root(tmp_root .. "/project/sub/deep", { ".git" })
		assert.are.equal(tmp_root .. "/project", root)
	end)

	it("should detect project root from the root itself", function()
		local root = finder.find_root(tmp_root .. "/project", { ".git" })
		assert.are.equal(tmp_root .. "/project", root)
	end)

	it("should support file markers like go.mod", function()
		local f = io.open(tmp_root .. "/project/sub/go.mod", "w")
		f:write("module example.com/foo\n")
		f:close()

		local root = finder.find_root(tmp_root .. "/project/sub/deep", { ".git", "go.mod" })
		assert.are.equal(tmp_root .. "/project/sub", root)
	end)

	it("should return start_dir when no marker is found", function()
		local root = finder.find_root(tmp_root .. "/project/sub/deep", { ".nonexistent-marker" })
		assert.are.equal(tmp_root .. "/project/sub/deep", root)
	end)

	it("should return start_dir when markers list is empty", function()
		local root = finder.find_root(tmp_root .. "/project/sub/deep", {})
		assert.are.equal(tmp_root .. "/project/sub/deep", root)
	end)
end)
