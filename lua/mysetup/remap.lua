vim.g.mapleader = " "

vim.keymap.set("n", "<leader>e", "<CMD>Oil<CR>") -- open oil

vim.keymap.set("n", "op", "o <Esc>k")            -- add line bellow
vim.keymap.set("n", "oi", "O <Esc>j")            -- add line above
vim.keymap.set("n", "oo", "o <Esc>")             -- add line

vim.keymap.set("n", "<leader>d", ":bd<CR>")      -- delete current buffer

vim.keymap.set("n", "<Tab>", ":bnext<CR>")       -- next buffer
vim.keymap.set("n", "<S-Tab>", ":bprev<CR>")     -- prev buffer

vim.keymap.set("n", "<C-j>", "<C-e>")            -- scoll down
vim.keymap.set("n", "<C-k>", "<C-y>")            -- scoll top

vim.keymap.set("n", "<C-d>", "<C-d>zz")          -- scoll down
vim.keymap.set("n", "<C-u>", "<C-u>zz")          -- scoll top

vim.keymap.set("x", "<leader>p", "\"_dP")        -- paste without copying

