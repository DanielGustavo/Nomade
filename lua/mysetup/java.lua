local mason_root = os.getenv("HOME") .. "/.config/nvim/mason"

vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4

    local jdtls = require("jdtls")

    -- Unique workspace per project to avoid cross-project cache pollution
    local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
    local workspace_dir = os.getenv("HOME") .. "/.local/share/nvim/jdtls-workspaces/" .. project_name

    -- Attach java-debug-adapter bundle if installed
    local bundles = {}
    local debug_jar = vim.fn.glob(
      mason_root .. "/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
      true
    )
    if debug_jar ~= "" then
      table.insert(bundles, debug_jar)
    end

    jdtls.start_or_attach({
      cmd = { mason_root .. "/bin/jdtls", "-data", workspace_dir },
      cmd_env = { JAVA_HOME = "/usr/lib/jvm/java-21-openjdk-amd64" },
      root_dir = vim.fs.root(0, { "pom.xml", "build.gradle", "build.gradle.kts", ".git", "mvnw", "gradlew" }),
      settings = {
        java = {
          eclipse = { downloadSources = true },
          maven = { downloadSources = true },
          signatureHelp = { enabled = true },
        },
      },
      init_options = { bundles = bundles },
    })

    -- Java-specific keymaps (buffer-local)
    local opts = { buffer = true }
    vim.keymap.set("n", "<leader>ji", jdtls.organize_imports,
      vim.tbl_extend("force", opts, { desc = "Java: Organize imports" }))
    vim.keymap.set("n", "<leader>jv", jdtls.extract_variable,
      vim.tbl_extend("force", opts, { desc = "Java: Extract variable" }))
    vim.keymap.set("v", "<leader>jv", function() jdtls.extract_variable(true) end,
      vim.tbl_extend("force", opts, { desc = "Java: Extract variable" }))
    vim.keymap.set("n", "<leader>jm", jdtls.extract_method,
      vim.tbl_extend("force", opts, { desc = "Java: Extract method" }))
    vim.keymap.set("v", "<leader>jm", function() jdtls.extract_method(true) end,
      vim.tbl_extend("force", opts, { desc = "Java: Extract method" }))

    -- Wire up DAP if debug adapter was found
    if #bundles > 0 then
      jdtls.setup_dap({ hotcodereplace = "auto" })
      require("jdtls.dap").setup_dap_main_class_configs()
    end
  end,
})
