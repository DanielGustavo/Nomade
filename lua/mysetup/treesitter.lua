require('nvim-treesitter.configs').setup({
  ensure_installed = {
    "javascript",
    "typescript",
    "lua",
    "vim",
    "vimdoc",
    "query",
    "markdown",
    "markdown_inline",
    "styled",
    "c",
    "cpp",
    "cmake"
  },

  sync_install = false,
  auto_install = true,

  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },

  modules = {},
  ignore_install = {},

  indent = {
    enable = true
  },
})
