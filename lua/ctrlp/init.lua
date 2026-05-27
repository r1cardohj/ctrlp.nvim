local M = {}

local ui = require("ctrlp.ui")
local finder = require("ctrlp.finder")
local matcher = require("ctrlp.matcher")

M.version = "0.0.1"

M.config = {
	max_files = 10000,
	ignore_patterns = {
		"^%.git/",
		"^node_modules/",
		"^%.hg/",
		"^%.svn/",
		"^target/",
		"^dist/",
		"^build/",
	},
}

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.open()
	local cwd = vim.fn.getcwd()
	local files = finder.scan(cwd, M.config)
	ui.open(files, M.config)
end

return M
