local function open_terminal(command, cwd)
  vim.cmd("botright 12split")
  vim.fn.termopen(command, {
    cwd = cwd or vim.fn.getcwd(),
    on_exit = function(_, code)
      if code ~= 0 then
        vim.schedule(function()
          vim.notify("Java command failed with exit code " .. code, vim.log.levels.WARN, { title = "Java" })
        end)
      end
    end,
  })
  vim.cmd("startinsert")
end

local function prompt_spring_initializr()
  local values = {}
  local prompts = {
    { "Group ID: ", "com.example" },
    { "Artifact ID: ", "demo" },
    { "Dependencies (comma-separated): ", "web" },
  }

  local function ask(index)
    if index > #prompts then
      local temporary = vim.fn.tempname()
      local script = table.concat({
        "set -eu",
        "curl --fail --silent --show-error --location --output "
          .. vim.fn.shellescape(temporary)
          .. " --get https://start.spring.io/starter.zip"
          .. " --data-urlencode "
          .. vim.fn.shellescape("type=maven-project")
          .. " --data-urlencode "
          .. vim.fn.shellescape("language=java")
          .. " --data-urlencode "
          .. vim.fn.shellescape("groupId=" .. values[1])
          .. " --data-urlencode "
          .. vim.fn.shellescape("artifactId=" .. values[2])
          .. " --data-urlencode "
          .. vim.fn.shellescape("name=" .. values[2])
          .. " --data-urlencode "
          .. vim.fn.shellescape("dependencies=" .. values[3]),
        "unzip -q " .. vim.fn.shellescape(temporary) .. " -d .",
        "rm -f " .. vim.fn.shellescape(temporary),
      }, "\n")
      open_terminal({ "sh", "-c", script })
      return
    end

    local prompt, default = unpack(prompts[index])
    vim.ui.input({ prompt = prompt, default = default }, function(value)
      if value and value ~= "" then
        values[index] = value
        ask(index + 1)
      end
    end)
  end

  ask(1)
end

vim.api.nvim_create_user_command("JavaMavenInit", function()
  open_terminal({ "mvn", "archetype:generate" })
end, {})

vim.api.nvim_create_user_command("JavaGradleInit", function()
  open_terminal({ "gradle", "init" })
end, {})

vim.api.nvim_create_user_command("JavaSpringInit", prompt_spring_initializr, {})

require("java").setup()
vim.lsp.enable("jdtls")

vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function(event)
    local function map(key, command, description)
      vim.keymap.set("n", key, command, { buffer = event.buf, desc = description })
    end

    map("<leader>jb", "<Cmd>JavaBuildBuildWorkspace<CR>", "Java: Build workspace")
    map("<leader>jc", "<Cmd>JavaBuildCleanWorkspace<CR>", "Java: Clean workspace")
    map("<leader>jr", "<Cmd>JavaRunnerRunMain<CR>", "Java: Run main class")
    map("<leader>jR", "<Cmd>JavaRunnerToggleLogs<CR>", "Java: Toggle runner logs")
    map("<leader>tr", "<Cmd>JavaTestRunCurrentMethod<CR>", "Java: Run current test")
    map("<leader>tD", "<Cmd>JavaTestDebugCurrentClass<CR>", "Java: Debug test class")
    map("<leader>td", "<Cmd>JavaTestDebugCurrentMethod<CR>", "Java: Debug current test")
    map("<leader>jo", function()
      vim.lsp.buf.code_action({ apply = true })
    end, "Java: Code actions")
  end,
})
