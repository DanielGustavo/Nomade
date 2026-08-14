local python = function()
  local ok, selector = pcall(require, "venv-selector")
  return ok and selector.python() or nil
end

require("venv-selector").setup({
  options = {
    cached_venv_automatic_activation = true,
  },
})

local neotest = require("neotest")
neotest.setup({
  adapters = {
    require("neotest-python")({
      python = python,
      runner = "pytest",
    }),
    require("neotest-java")({}),
  },
})

local iron = require("iron.core")
local view = require("iron.view")
local common = require("iron.fts.common")

iron.setup({
  config = {
    scratch_repl = true,
    repl_definition = {
      python = {
        command = function()
          return { python() or "python3" }
        end,
        format = common.bracketed_paste_python,
        block_dividers = { "# %%", "#%%" },
        env = { PYTHON_BASIC_REPL = "1" },
      },
    },
    repl_open_cmd = view.bottom(12),
    dap_integration = true,
  },
  keymaps = {
    toggle_repl = "<leader>rr",
    restart_repl = "<leader>rR",
    send_file = "<leader>sf",
    send_line = "<leader>sl",
    send_motion = "<leader>sc",
    visual_send = "<leader>sc",
    send_code_block = "<leader>sb",
    interrupt = "<leader>s<Space>",
  },
})

vim.keymap.set("n", "<leader>pv", "<CMD>VenvSelect<CR>", { desc = "Python: Select environment" })
vim.keymap.set("n", "<leader>tt", function()
  neotest.run.run()
end, { desc = "Test: Run nearest" })
vim.keymap.set("n", "<leader>tf", function()
  neotest.run.run(vim.fn.expand("%"))
end, { desc = "Test: Run file" })
vim.keymap.set("n", "<leader>to", function()
  neotest.output.open({ enter = true })
end, { desc = "Test: Show output" })
vim.keymap.set("n", "<leader>ts", function()
  neotest.summary.toggle()
end, { desc = "Test: Toggle summary" })
