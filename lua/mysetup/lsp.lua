local defaultCapabilities = vim.lsp.protocol.make_client_capabilities()
vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(defaultCapabilities),
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = event.buf, desc = "LSP: Hover" })
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = event.buf, desc = "LSP: Go to definition" })
    vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = event.buf, desc = "LSP: Go to references" })
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = event.buf, desc = "LSP: Rename symbol" })
    vim.keymap.set("n", "[d", function()
      vim.diagnostic.goto_next()
      vim.cmd("normal! zz")
    end, { buffer = event.buf, desc = "LSP: Next diagnostic" })
    vim.keymap.set("n", "]d", function()
      vim.diagnostic.goto_prev()
      vim.cmd("normal! zz")
    end, { buffer = event.buf, desc = "LSP: Previous diagnostic" })
  end,
})

local servers_to_configure = {
  ["lua_ls"] = {
    settings = {
      Lua = {
        workspace = {
          checkThirdParty = false,
          ignoreDir = { "mason/packages" },
        },
        telemetry = { enable = false },
      },
    },
    root_markers = { ".luarc.json" },
  },

  ["ts_ls"] = {
    root_markers = { ".git", "tsconfig.json", "jsconfig.json" },
  },

  ["jsonls"] = {},
  ["eslint"] = {},
  ["prismals"] = {},
  ["tailwindcss"] = {},

  ["clangd"] = {
    root_markers = { "compile_commands.json", ".clangd", "CMakeLists.txt", ".git" },
    cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
  },

  ["cmake"] = {
    root_markers = { "CMakeLists.txt", ".git" },
  },
}

local styled_plugin_path = vim.fn.stdpath("config") .. "/node_modules/@styled/typescript-styled-plugin"
if vim.fn.isdirectory(styled_plugin_path) == 1 then
  servers_to_configure.ts_ls.init_options = {
    plugins = {
      {
        name = "@styled/typescript-styled-plugin",
        location = styled_plugin_path,
      },
    },
  }
end

require("mason-lspconfig").setup({
  ensure_installed = vim.tbl_keys(servers_to_configure),
  automatic_enable = false,
})

local mason_registry = require("mason-registry")
if not vim.tbl_contains(vim.v.argv, "--headless") then
  mason_registry.refresh(function(success)
    if not success then
      vim.notify("Could not refresh the Mason registry for CodeLLDB", vim.log.levels.WARN)
      return
    end

    local ok, codelldb_package = pcall(mason_registry.get_package, "codelldb")
    if not ok then
      vim.notify("CodeLLDB is unavailable in the Mason registry", vim.log.levels.WARN)
      return
    end

    if not codelldb_package:is_installed() then
      codelldb_package:install()
    end
  end)
end

for server, config in pairs(servers_to_configure) do
  vim.lsp.config(server, config)
end

vim.lsp.enable(vim.tbl_keys(servers_to_configure))
