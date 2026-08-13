vim.g.mapleader = " "

vim.keymap.set("n", "<leader>e", "<CMD>Oil<CR>", { desc = "Open Oil" })

vim.keymap.set("n", "op", "o <Esc>k", { desc = "Add line below" })
vim.keymap.set("n", "oi", "O <Esc>j", { desc = "Add line above" })
vim.keymap.set("n", "oo", "o <Esc>", { desc = "Add line below" })

vim.keymap.set("n", "<leader>d", ":bd<CR>", { desc = "Delete current buffer" })

vim.keymap.set("n", "<Tab>", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-Tab>", ":bprev<CR>", { desc = "Previous buffer" })

vim.keymap.set("n", "<C-j>", "<C-e>", { desc = "Scroll down" })
vim.keymap.set("n", "<C-k>", "<C-y>", { desc = "Scroll up" })

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })

vim.keymap.set("x", "<leader>p", "\"_dP", { desc = "Paste without copying" })
