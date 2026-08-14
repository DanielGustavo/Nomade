local project_config = require("mysetup.project_config")

local servers_to_configure = {
  lua_ls = {
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

  ts_ls = {
    root_markers = { ".git", "tsconfig.json", "jsconfig.json" },
  },

  jsonls = {},
  eslint = {
    root_dir = function(bufnr, on_dir)
      local root = project_config.root(bufnr, {
        [[\v^eslint\.config\..+$]],
        [[\v^\.eslintrc(\..*)?$]],
      }, "eslintConfig")
      if root then
        on_dir(root)
      end
    end,
  },
  prismals = {},
  tailwindcss = {},

  clangd = {
    root_markers = { "compile_commands.json", ".clangd", "CMakeLists.txt", ".git" },
    cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
  },

  cmake = {
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

vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities()),
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    local function map(key, action, description)
      vim.keymap.set("n", key, action, { buffer = event.buf, desc = description })
    end

    map("K", vim.lsp.buf.hover, "LSP: Hover")
    map("gd", vim.lsp.buf.definition, "LSP: Go to definition")
    map("gr", vim.lsp.buf.references, "LSP: Go to references")
    map("<leader>rn", vim.lsp.buf.rename, "LSP: Rename symbol")
    map("[d", function()
      vim.diagnostic.goto_next()
      vim.cmd("normal! zz")
    end, "LSP: Next diagnostic")
    map("]d", function()
      vim.diagnostic.goto_prev()
      vim.cmd("normal! zz")
    end, "LSP: Previous diagnostic")
  end,
})

require("mysetup.mason_lock")(servers_to_configure, { "codelldb", "stylua" })

for server_name, config in pairs(servers_to_configure) do
  vim.lsp.config(server_name, config)
end

vim.lsp.enable(vim.tbl_keys(servers_to_configure))

vim.lsp.config("biome", {
  cmd = { "biome", "lsp-proxy" },
  root_dir = function(bufnr, on_dir)
    local root = project_config.root(bufnr, { [[\v^biome\.jsonc?$]] })
    if root then
      on_dir(root)
    end
  end,
})
vim.lsp.enable("biome")
