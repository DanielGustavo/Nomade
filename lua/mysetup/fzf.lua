require('fzf-lua').setup()

local fzfLua = require('fzf-lua')

function getUnmerged()
  fzfLua.files({
    cmd = 'git ls-files --unmerged',
    winopts = {
      height = 0.5,
      width = 0.8,
    },
    previewer = 'builtin',
  })
end

vim.keymap.set("n", "<leader>f", fzfLua.files, {})
vim.keymap.set("n", "<leader>ps", fzfLua.live_grep, {})
vim.keymap.set("n", "<F4>", fzfLua.lsp_code_actions, {})
vim.keymap.set("n", "<leader>pd", fzfLua.diagnostics_document, {})
vim.keymap.set("n", "<leader>gg", fzfLua.git_status, {})
vim.keymap.set("n", "<leader>gu", getUnmerged, {})
