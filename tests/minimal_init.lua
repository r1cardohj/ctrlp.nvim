-- 测试用的最小化 Neovim 环境
-- 把当前项目根目录加入 runtimepath，确保能 require("ctrlp.xxx")
local root = vim.fn.fnamemodify(".", ":p")
vim.opt.rtp:prepend(root)

-- 自动下载 plenary.nvim 到项目根目录的 .deps 目录（避免污染用户的插件目录，也不被测试扫描）
local plenary_path = root .. "/.deps/plenary.nvim"
if vim.fn.isdirectory(plenary_path) == 0 then
	vim.fn.system({
		"git", "clone", "--depth", "1",
		"https://github.com/nvim-lua/plenary.nvim",
		plenary_path,
	})
end
vim.opt.rtp:prepend(plenary_path)
