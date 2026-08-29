local M = {}

local ui = require("ctrlp.ui")
local finder = require("ctrlp.finder")
local matcher = require("ctrlp.matcher")

M.version = "0.0.1"

M.config = {
	max_files = 10000,
	use_cache = true,
	ignore_patterns = {
		"^%.git/",
		"^node_modules/",
		"^%.hg/",
		"^%.svn/",
		"^target/",
		"^dist/",
		"^build/",
	},
	root_markers = { ".git", ".hg", ".svn", "package.json", "go.mod", "Cargo.toml" },
}

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.open()
	local cwd = vim.fn.getcwd()
	local root = finder.find_root(cwd, M.config.root_markers)
	local files = finder.scan(root, M.config)
	ui.open(files, M.config, root)
end

return M
