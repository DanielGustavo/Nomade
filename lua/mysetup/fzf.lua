local fzfLua = require('fzf-lua')

fzfLua.setup({
  defaults = {
    file_icons = true,
  },
  files = {
    cmd = [[fdfind --type f --exclude .git --exclude node_modules]],
  },
  grep = {
    rg_opts =
    "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 -g '!.git/*' -g '!node_modules/*'",
  }
})

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

-- Keymaps
vim.keymap.set("n", "<leader>f", fzfLua.files, {})
vim.keymap.set("n", "<leader>ps", fzfLua.live_grep, {})
vim.keymap.set("n", "<F4>", fzfLua.lsp_code_actions, {})
vim.keymap.set("n", "<leader>pd", fzfLua.diagnostics_document, {})
vim.keymap.set("n", "<leader>gg", fzfLua.git_status, {})
vim.keymap.set("n", "<leader>gu", getUnmerged, {})
