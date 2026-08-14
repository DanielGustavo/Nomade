local project_config = require("mysetup.project_config")
local java_google_format = vim.fn.stdpath("data") .. "/mason/bin/google-java-format"

local function java_build_file(root)
  for _, name in ipairs({ "pom.xml", "build.gradle", "build.gradle.kts" }) do
    local path = root .. "/" .. name
    if vim.fn.filereadable(path) == 1 then
      return path, table.concat(vim.fn.readfile(path), "\n")
    end
  end
end

local function java_project_formatter(bufnr)
  local root = project_config.root(bufnr, { [[\v^(pom\.xml|build\.gradle(\.kts)?)$]] })
  if not root then
    return nil
  end

  local path, contents = java_build_file(root)
  if not path then
    return nil
  end

  if contents:find("spotless", 1, true) then
    return path:match("pom%.xml$") and { "spotless:apply" } or { "spotlessApply" }
  end
  if contents:find("formatter%-maven%-plugin") then
    return { "formatter:format" }
  end
end

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
    java = { "java_project", "java_google_format", stop_after_first = true },
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
    java_project = {
      command = function(_, context)
        local root = project_config.root(context.buf, { [[\v^(pom\.xml|build\.gradle(\.kts)?)$]] })
        local is_maven = vim.fn.filereadable(root .. "/pom.xml") == 1
        if is_maven and vim.fn.filereadable(root .. "/mvnw") == 1 then
          return root .. "/mvnw"
        end
        if not is_maven and vim.fn.filereadable(root .. "/gradlew") == 1 then
          return root .. "/gradlew"
        end
        if is_maven then
          return "mvn"
        end
        return "gradle"
      end,
      args = function(_, context)
        return java_project_formatter(context.buf)
      end,
      cwd = function(_, context)
        return project_config.root(context.buf, { [[\v^(pom\.xml|build\.gradle(\.kts)?)$]] })
      end,
      stdin = false,
      condition = function(_, context)
        return java_project_formatter(context.buf) ~= nil
      end,
    },
    java_google_format = {
      command = java_google_format,
      args = { "-" },
      condition = function()
        return vim.fn.executable(java_google_format) == 1
      end,
    },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_format = "never",
  },
})
