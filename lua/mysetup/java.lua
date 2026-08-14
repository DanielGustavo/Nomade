local data_dir = vim.fn.stdpath("data")
local notified = {}

local function notify_once(root, message, level)
  local key = root .. ":" .. message
  if notified[key] then
    return
  end
  notified[key] = true
  vim.notify(message, level, { title = "Java" })
end

local function project_root(bufnr)
  return vim.fs.root(bufnr, { ".git", "mvnw", "gradlew" })
end

local function command_output(command, cwd)
  if vim.fn.executable(command[1]) ~= 1 then
    return nil
  end

  local result = vim.system(command, { cwd = cwd, text = true }):wait()
  if result.code == 0 then
    return vim.trim(result.stdout or "")
  end
end

local function java_home(root)
  for _, manager in ipairs({ "mise", "asdf" }) do
    local selected = command_output({ manager, "where", "java" }, root)
    if selected and selected ~= "" then
      return selected
    end
  end

  local home = vim.env.JAVA_HOME
  if home and home ~= "" then
    return home
  end
end

local function java_major(executable, cwd)
  if vim.fn.executable(executable) ~= 1 and not executable:find("/", 1, true) then
    return nil
  end

  local result = vim.system({ executable, "-version" }, { cwd = cwd, text = true }):wait()
  local version = (result.stderr or "") .. (result.stdout or "")
  local value = version:match('version "([^"]+)"')
  if not value then
    return nil
  end

  local major = tonumber(value:match("^(%d+)"))
  return major == 1 and tonumber(value:match("^1%.(%d+)")) or major
end

local function current_java_home()
  local executable = vim.fn.exepath("java")
  if executable == "" then
    return nil
  end
  return vim.fn.fnamemodify(vim.fn.resolve(executable), ":h:h")
end

local function java_bundles()
  local bundles = {}
  local debug_bundle = vim.fn.glob(
    data_dir .. "/mason/packages/java-debug-adapter/java-debug-adapter/com.microsoft.java.debug.plugin*.jar",
    true,
    true
  )
  vim.list_extend(bundles, debug_bundle)

  local test_bundles = vim.fn.glob(data_dir .. "/mason/packages/java-test/java-test/*.jar", true, true)
  for _, bundle in ipairs(test_bundles) do
    local name = vim.fn.fnamemodify(bundle, ":t")
    if name ~= "com.microsoft.java.test.runner-jar-with-dependencies.jar" and name ~= "jacocoagent.jar" then
      bundles[#bundles + 1] = bundle
    end
  end
  return bundles
end

local function set_java_maps(bufnr)
  local function map(key, action, description)
    vim.keymap.set("n", key, action, { buffer = bufnr, desc = description })
  end

  map("<leader>jo", function()
    require("jdtls").organize_imports()
  end, "Java: Organize imports")
  map("<leader>td", function()
    require("jdtls").test_nearest_method()
  end, "Java: Debug nearest test")
  map("<leader>tD", function()
    require("jdtls").test_class()
  end, "Java: Debug test class")
end

local function start_jdtls(bufnr)
  local root = project_root(bufnr)
  if not root then
    notify_once("unknown", "Java project root not found; expected .git, mvnw, or gradlew", vim.log.levels.WARN)
    return
  end

  local jdtls = data_dir .. "/mason/bin/jdtls"
  if vim.fn.executable(jdtls) ~= 1 then
    notify_once(root, "JDTLS is unavailable; Mason should install the locked jdtls package", vim.log.levels.WARN)
    return
  end

  local home = java_home(root)
  local current_home = current_java_home()
  local selected_major = home and java_major(home .. "/bin/java", root) or java_major("java", root)
  local current_major = java_major("java", root)
  local server_home = home
  if not server_home or (selected_major and selected_major < 21) then
    server_home = current_home
  end

  if not server_home or not current_major then
    notify_once(root, "Java is unavailable; configure a JDK through mise/asdf or JAVA_HOME", vim.log.levels.WARN)
    return
  end
  local server_major = java_major(server_home .. "/bin/java", root)
  if not server_major or server_major < 21 then
    notify_once(root, "JDTLS requires Java 21; install it alongside the project JDK", vim.log.levels.WARN)
    return
  end

  local cmd_env = {
    JAVA_HOME = server_home,
    PATH = server_home .. "/bin:" .. (vim.env.PATH or ""),
  }
  local workspace = data_dir .. "/jdtls/" .. vim.fn.sha256(root)
  vim.fn.mkdir(workspace, "p")

  local config = {
    cmd = { jdtls, "-data", workspace },
    cmd_env = cmd_env,
    root_dir = root,
    settings = {
      java = {
        configuration = {
          updateBuildConfiguration = "interactive",
        },
        import = {
          gradle = { enabled = true },
          maven = { enabled = true },
        },
      },
    },
    init_options = {
      bundles = java_bundles(),
    },
  }

  if home and selected_major then
    config.settings.java.configuration.runtimes = {
      {
        name = "JavaSE-" .. selected_major,
        path = home,
      },
    }
  end

  require("jdtls").start_or_attach(config)
  set_java_maps(bufnr)
end

local function project_command(root, args)
  local tool
  if vim.fn.filereadable(root .. "/mvnw") == 1 then
    tool = "./mvnw"
  elseif vim.fn.filereadable(root .. "/gradlew") == 1 then
    tool = "./gradlew"
  elseif vim.fn.executable("mvn") == 1 then
    tool = "mvn"
  elseif vim.fn.executable("gradle") == 1 then
    tool = "gradle"
  end

  if not tool then
    notify_once(root, "Neither Maven nor Gradle is available for this Java project", vim.log.levels.WARN)
    return
  end

  local task = args[1]
  if task == "build" and (tool == "mvn" or tool == "./mvnw") then
    args = { "package" }
  end

  local command = { tool }
  if vim.fn.filereadable(root .. "/.tool-versions") == 1 and vim.fn.executable("mise") == 1 then
    command = { "mise", "exec", "--", tool }
  elseif vim.fn.filereadable(root .. "/.tool-versions") == 1 and vim.fn.executable("asdf") == 1 then
    command = { "asdf", "exec", tool }
  end
  vim.list_extend(command, args)
  vim.cmd("botright 12split")
  vim.fn.termopen(command, {
    cwd = root,
    on_exit = function(_, code)
      if code ~= 0 then
        vim.schedule(function()
          vim.notify("Java task failed with exit code " .. code, vim.log.levels.WARN, { title = "Java" })
        end)
      end
    end,
  })
  vim.cmd("startinsert")
end

local function run_task(bufnr, args)
  local root = project_root(bufnr)
  if root then
    project_command(root, args)
  else
    notify_once("unknown", "Java project root not found; cannot run a build task", vim.log.levels.WARN)
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function(event)
    start_jdtls(event.buf)

    vim.keymap.set("n", "<leader>jb", function()
      run_task(event.buf, { "build" })
    end, { buffer = event.buf, desc = "Java: Build project" })
    vim.keymap.set("n", "<leader>jt", function()
      run_task(event.buf, { "test" })
    end, { buffer = event.buf, desc = "Java: Run project tests" })
    vim.keymap.set("n", "<leader>jc", function()
      run_task(event.buf, { "clean" })
    end, { buffer = event.buf, desc = "Java: Clean project" })
  end,
})
