local project_config = require("mysetup.project_config")

require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    javascript = { "biome", "prettierd", stop_after_first = true },
    javascriptreact = { "biome", "prettierd", stop_after_first = true },
    typescript = { "biome", "prettierd", stop_after_first = true },
    typescriptreact = { "biome", "prettierd", stop_after_first = true },
    c = { "clang-format" },
    cpp = { "clang-format" },
    python = { "ruff_format" },
    java = { lsp_format = "first" },
  },
  formatters = {
    stylua = {
      condition = function(_, context)
        return project_config.has(context.buf, { [[\v^\.stylua\.toml$]], [[\v^stylua\.toml$]] })
      end,
    },
    biome = {
      condition = function(_, context)
        return project_config.has(context.buf, { [[\v^biome\.jsonc?$]] })
      end,
    },
    prettierd = {
      condition = function(_, context)
        return project_config.has(context.buf, {
          [[\v^\.prettierrc(\..*)?$]],
          [[\v^prettier\.config\..+$]],
        }, "prettier")
      end,
    },
    ["clang-format"] = {
      condition = function(_, context)
        return project_config.has(context.buf, { [[\v^[_.]clang-format$]] })
      end,
    },
    ruff_format = {
      condition = function(_, context)
        return project_config.has(context.buf, {
          [[\v^pyproject\.toml$]],
          [[\v^ruff\.toml$]],
          [[\v^\.ruff\.toml$]],
          [[\v^uv\.lock$]],
        })
      end,
    },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "never",
  },
})
