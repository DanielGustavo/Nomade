require("blink.cmp").setup({
  keymap = {
    ['<S-Tab>'] = { 'select_prev', 'fallback' },
    ['<Tab>'] = { 'select_next', 'fallback' },
    ['<C-e>'] = false,
    ['<C-k>'] = { 'show', 'hide', 'fallback' },
    ['<CR>'] = { 'accept', 'fallback' }
  },
  appearance = {
    nerd_font_variant = 'normal'
  },
  completion = {
    documentation = {
      auto_show = true,
    },
    accept = { auto_brackets = { enabled = false } },
  },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer' },
  },
  fuzzy = { implementation = "prefer_rust_with_warning" }
})
