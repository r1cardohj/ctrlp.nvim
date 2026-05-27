if vim.g.loaded_ctrlp then
	return
end
vim.g.loaded_ctrlp = 1

vim.api.nvim_create_user_command("CtrlP", function()
	require("ctrlp").open()
end, {})

vim.api.nvim_set_keymap("n", "<C-p>", "<Cmd>CtrlP<CR>", { noremap = true, silent = true, desc = "Open CtrlP fuzzy finder" })
