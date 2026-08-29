local M = {}

local ui = require("ctrlp.ui")
local finder = require("ctrlp.finder")
local matcher = require("ctrlp.matcher")

M.version = "0.0.1"

M.config = {
	max_files = 10000,
	use_cache = true,
	show_hidden = false, -- exclude dotfiles/dot-directories (.git, .idea, ...)
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

--- Register MRU tracking autocmds (mirrors ctrlp.vim): record normal file
--- buffers as they are entered, persist the history when leaving Vim.
--- Idempotent; called automatically from plugin/ctrlp.lua.
function M.setup_mru_tracking()
	local mru = require("ctrlp.mru")
	local group = vim.api.nvim_create_augroup("CtrlpMru", { clear = true })
	vim.api.nvim_create_autocmd("BufEnter", {
		group = group,
		callback = function(args)
			local buf = args.buf
			if vim.bo[buf].buftype == "" and vim.bo[buf].buflisted then
				mru.record(vim.api.nvim_buf_get_name(buf))
			end
		end,
	})
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			mru.save()
		end,
	})
end

--- Open the finder in the given mode ("files" by default, see
--- require("ctrlp.modes").order for available modes).
function M.open(mode)
	local cwd = vim.fn.getcwd()
	local root = finder.find_root(cwd, M.config.root_markers)
	ui.open(M.config, root, mode)
end

return M
