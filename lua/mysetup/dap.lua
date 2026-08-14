local dap = require("dap")
local dapui = require("dapui")

local codelldb = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/adapter/codelldb"

-- Adapter
dap.adapters.codelldb = function(callback, _)
  if vim.fn.executable(codelldb) ~= 1 then
    vim.notify("codelldb not found. Mason should install it automatically", vim.log.levels.ERROR)
    return
  end
  callback({
    type = "server",
    port = "${port}",
    executable = {
      command = codelldb,
      args = { "--port", "${port}" },
    },
  })
end

-- Cache executable path — ask once, remember for the session
local executable_path = nil

-- C / C++ launch configuration
local cpp_configs = {
  {
    name = "Launch executable",
    type = "codelldb",
    request = "launch",
    program = function()
      if not executable_path or executable_path == "" then
        executable_path = vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
      end
      return executable_path
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
  },
}

dap.configurations.cpp = cpp_configs
dap.configurations.c = cpp_configs

-- UI
dapui.setup()

dap.listeners.before.attach.dapui_config = function()
  dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
  dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
  dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
  dapui.close()
end

-- Keymaps
vim.keymap.set("n", "<leader>DC", dap.continue, { desc = "DAP: Continue / Start" })
vim.keymap.set("n", "<leader>DO", dap.step_over, { desc = "DAP: Step over" })
vim.keymap.set("n", "<leader>DI", dap.step_into, { desc = "DAP: Step into" })
vim.keymap.set("n", "<leader>DQ", dap.step_out, { desc = "DAP: Step out" })
vim.keymap.set("n", "<leader>DB", dap.toggle_breakpoint, { desc = "DAP: Toggle breakpoint" })
vim.keymap.set("n", "<leader>DU", dapui.toggle, { desc = "DAP: Toggle UI" })
vim.keymap.set("n", "<leader>DE", dapui.eval, { desc = "DAP: Eval expression" })
vim.keymap.set("n", "<leader>DP", function()
  executable_path = vim.fn.input("Path to executable: ", executable_path or (vim.fn.getcwd() .. "/"), "file")
end, { desc = "DAP: Set program path" })
