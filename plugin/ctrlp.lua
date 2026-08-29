if vim.g.loaded_ctrlp then
	return
end
vim.g.loaded_ctrlp = 1

vim.api.nvim_create_user_command("CtrlP", function()
	require("ctrlp").open()
end, {})

vim.api.nvim_create_user_command("CtrlPBuffer", function()
	require("ctrlp").open("buffers")
end, {})

vim.api.nvim_create_user_command("CtrlPMRU", function()
	require("ctrlp").open("mru")
end, {})

vim.api.nvim_create_user_command("CtrlPClearCache", function()
	require("ctrlp.finder").clear_cache()
	vim.notify("CtrlP cache cleared", vim.log.levels.INFO)
end, {})

vim.api.nvim_set_keymap("n", "<C-p>", "<Cmd>CtrlP<CR>", { noremap = true, silent = true, desc = "Open CtrlP fuzzy finder" })

require("ctrlp").setup_mru_tracking()
