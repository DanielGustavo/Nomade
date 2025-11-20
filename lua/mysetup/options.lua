local options = {
  autoindent = true,
  smartindent = true,
  expandtab = true,
  tabstop = 2,
  shiftwidth = 2,

  number = true,
  relativenumber = true,

  swapfile = false,
  backup = false,
  undodir = os.getenv("HOME") .. "/.vim/undodir",
  undofile = true,

  hlsearch = false,
  incsearch = true,
}

-- Apply options
for option, value in pairs(options) do
  vim.opt[option] = value
end

