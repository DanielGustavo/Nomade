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

local mason_lspconfig = require("mason-lspconfig")
local mason_mappings = mason_lspconfig.get_mappings()
local expected_mason_packages = { codelldb = true }

for server_name in pairs(servers_to_configure) do
  expected_mason_packages[mason_mappings.lspconfig_to_package[server_name]] = true
end

local mason_lock = require("mysetup.mason_lock")
local mason_package_versions = mason_lock.load(expected_mason_packages)

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

mason_lspconfig.setup({
  ensure_installed = mason_package_versions and mason_lock.versioned_specs(
    servers_to_configure,
    mason_package_versions,
    mason_mappings
  ) or {},
  automatic_enable = false,
})

local mason_registry = require("mason-registry")
if mason_package_versions and not vim.tbl_contains(vim.v.argv, "--headless") then
  mason_registry.refresh(function(success)
    if not success then
      vim.notify("Could not refresh the Mason registry for CodeLLDB", vim.log.levels.WARN)
      return
    end

    mason_lock.reconcile_installed(mason_package_versions, mason_registry)

    local ok, codelldb_package = pcall(mason_registry.get_package, "codelldb")
    if not ok then
      vim.notify("CodeLLDB is unavailable in the Mason registry", vim.log.levels.WARN)
      return
    end

    if not codelldb_package:is_installed() then
      codelldb_package:install({ version = mason_package_versions.codelldb }, function(install_success, install_err)
        if not install_success then
          vim.notify(("Could not install codelldb@%s: %s"):format(mason_package_versions.codelldb, install_err),
            vim.log.levels.ERROR)
        end
      end)
    end
  end)
end

for server, config in pairs(servers_to_configure) do
  vim.lsp.config(server, config)
end

vim.lsp.enable(vim.tbl_keys(servers_to_configure))
