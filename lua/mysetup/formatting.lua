local project_config = require("mysetup.project_config")

require("conform").setup({
  formatters_by_ft = {
    javascript = { "biome", "prettierd", stop_after_first = true },
    javascriptreact = { "biome", "prettierd", stop_after_first = true },
    typescript = { "biome", "prettierd", stop_after_first = true },
    typescriptreact = { "biome", "prettierd", stop_after_first = true },
    c = { "clang-format" },
    cpp = { "clang-format" },
  },
  formatters = {
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
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "never",
  },
})
