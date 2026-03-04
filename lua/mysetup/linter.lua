require("conform").setup({
  formatters_by_ft = {
    javascript = { "prettierd" },
    typescript = { "prettierd" },
    c = { "clang-format" },
    cpp = { "clang-format" },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "fallback",
  },
})
