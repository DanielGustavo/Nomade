local masonDir = vim.fn.stdpath("data") .. "/mason"
vim.fn.mkdir(masonDir, "p")

require("mason").setup({
  install_root_dir = masonDir,
})
