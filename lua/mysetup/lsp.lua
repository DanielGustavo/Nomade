local defaultCapabilities = vim.lsp.protocol.make_client_capabilities()
vim.lsp.config('*', {
  capabilities = require('blink.cmp').get_lsp_capabilities(defaultCapabilities)
})

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(event)
    local opts = { buffer = event.buf }

    vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)            -- hover
    vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)      -- go to definition
    vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)      -- go to references
    vim.keymap.set('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)  -- rename
    vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_next()<cr>zz', opts)  -- go to next error
    vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_prev()<cr>zz', opts)  -- got to previous error
  end,
})

local servers_to_configure = {
  ['lua_ls'] = {
    settings = {
      Lua = {
        workspace = {
          checkThirdParty = false,
          ignoreDir = { "mason/packages" },
        },
        telemetry = { enable = false },
      },
    },
    root_markers = { '.luarc.json' },
  },

  ['ts_ls'] = {
    root_markers = { '.git', 'tsconfig.json', 'jsconfig.json' },
    init_options = {
      plugins = {
        {
          name = "@styled/typescript-styled-plugin",
          location = os.getenv("HOME") .. "/.config/nvim/node_modules/@styled/typescript-styled-plugin"
        },
      },
    }
  },

  ['jsonls'] = {},
}

require('mason-lspconfig').setup({
  ensure_installed = vim.tbl_keys(servers_to_configure),
  automatic_enable = false
})

for server, config in pairs(servers_to_configure) do
  vim.lsp.config(server, config)
end

require('nvim-eslint').setup()
vim.lsp.enable(vim.tbl_keys(servers_to_configure))
