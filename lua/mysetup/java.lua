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

local function source_root(root, directory)
  local current = directory
  while current and current ~= root and current ~= "/" do
    local parent = vim.fs.dirname(current)
    if vim.fs.basename(current) == "java" then
      local scope = parent and vim.fs.basename(parent)
      local source = parent and vim.fs.basename(vim.fs.dirname(parent))
      if (scope == "main" or scope == "test") and source == "src" then
        return current
      end
    end
    current = parent
  end
end

local function java_package()
  local path = vim.fn.expand("%:p:h")
  local root = vim.fs.root(0, { ".git", "mvnw", "gradlew" })
  local source = root and source_root(root, path)
  if not source then
    return ""
  end

  local relative = path:sub(#source + 2)
  return relative == "" and "" or "package " .. relative:gsub("/", ".") .. ";"
end

local function test_directory(root, directory)
  local main_root = source_root(root, directory)
  if main_root and vim.fs.basename(vim.fs.dirname(main_root)) == "main" then
    local test_root = vim.fs.dirname(vim.fs.dirname(main_root)) .. "/test/java"
    return test_root .. directory:sub(#main_root + 1)
  end
  return directory
end

local function template_path(kind, name, is_test)
  if not name or name == "" then
    return
  end
  name = name:gsub("%.java$", "")
  if not name:match("^[%a_][%w_]*$") then
    vim.notify("Java type names must be valid identifiers", vim.log.levels.ERROR, { title = "Java" })
    return
  end

  local root = vim.fs.root(0, { ".git", "mvnw", "gradlew" })
  if not root then
    vim.notify("Java project root not found", vim.log.levels.WARN, { title = "Java" })
    return
  end

  local current = vim.api.nvim_buf_get_name(0)
  local directory = current == "" and vim.fn.getcwd() or vim.fs.dirname(current)
  if is_test then
    directory = test_directory(root, directory)
  end

  local path = directory .. "/" .. name .. ".java"
  if vim.fn.filereadable(path) == 1 then
    vim.notify("File already exists: " .. path, vim.log.levels.WARN, { title = "Java" })
    return
  end

  vim.fn.mkdir(directory, "p")
  local cwd = vim.fn.getcwd()
  vim.cmd("lcd " .. vim.fn.fnameescape(directory))
  vim.cmd("Template " .. vim.fn.fnameescape(name .. ".java") .. " " .. kind)
  vim.cmd("lcd " .. vim.fn.fnameescape(cwd))
end

local function create_command(command, kind, is_test)
  vim.api.nvim_create_user_command(command, function(opts)
    local function create(name)
      template_path(kind, name, is_test)
    end

    if opts.args ~= "" then
      create(opts.args)
      return
    end

    local current = vim.fs.basename(vim.api.nvim_buf_get_name(0)):match("^(.*)%.java$")
    local default = is_test and current and (current:match("Test$") and current or current .. "Test") or nil
    vim.ui.input({ prompt = "Java type name: ", default = default }, create)
  end, { nargs = "?" })
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

create_command("JavaNewClass", "class", false)
create_command("JavaNewInterface", "interface", false)
create_command("JavaNewEnum", "enum", false)
create_command("JavaNewRecord", "record", false)
create_command("JavaNewAnnotation", "annotation", false)
create_command("JavaNewTest", "test", true)

vim.api.nvim_create_user_command("JavaMavenInit", function()
  open_terminal({ "mvn", "archetype:generate" })
end, {})

vim.api.nvim_create_user_command("JavaGradleInit", function()
  open_terminal({ "gradle", "init" })
end, {})

vim.api.nvim_create_user_command("JavaSpringInit", prompt_spring_initializr, {})

require("template").setup({ temp_dir = vim.fn.stdpath("config") .. "/templates" })
require("template").register("{{_java_package_}}", java_package)

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
    map("<leader>jn", "<Cmd>JavaNewClass<CR>", "Java: Create class")
    map("<leader>jT", "<Cmd>JavaNewTest<CR>", "Java: Create test")
    map("<leader>tr", "<Cmd>JavaTestRunCurrentMethod<CR>", "Java: Run current test")
    map("<leader>tD", "<Cmd>JavaTestDebugCurrentClass<CR>", "Java: Debug test class")
    map("<leader>td", "<Cmd>JavaTestDebugCurrentMethod<CR>", "Java: Debug current test")
    map("<leader>jo", function()
      vim.lsp.buf.code_action({ apply = true })
    end, "Java: Code actions")
  end,
})
