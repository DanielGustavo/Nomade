local defaultRootMarkers = { '.git' }
local servers = {}

local mason_registry_ok, mason_registry = pcall(require, 'mason-registry')

function addServer(masonOpt, cmd, filetypes, rootMarkers, customConfig)
  local server = {
    name = masonOpt.name,
    command = cmd,
    fileTypes = filetypes,
    rootMarkers = {
      unpack(defaultRootMarkers),
      unpack(rootMarkers ~= nil and rootMarkers or {})
    },
    config = customConfig ~= nil and customConfig or {}
  }

  if mason_registry_ok then
    local package_name = masonOpt.name

    if package_name then
      local pkg = mason_registry.get_package(package_name)

      if pkg and not pkg:is_installed() then
        vim.notify("Mason: installing '" .. package_name .. "'... (run ':Mason' to check progress)", vim.log.levels.INFO, { title = "LSP Install" })
        pkg:install({ version = masonOpt.version })
      elseif not pkg then
        vim.notify("Mason: package '" .. package_name .. "' not found.", vim.log.levels.WARN, { title = "LSP Install" })
      end
    end
  end

  table.insert(servers, server)

  vim.lsp.config[server.name] = {
    cmd = server.command,
    filetypes = server.fileTypes,
    root_markers = server.rootMarkers,
    settings = server.config,
  }
end

function enableServers()
  for i, server in ipairs(servers) do
    vim.lsp.enable(server.name)
  end
end

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(event)
    local opts = { buffer = event.buf }

    vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)            -- hover
    vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)      -- go to definition
    vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)      -- go to references
    vim.keymap.set('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)  -- rename
    vim.keymap.set('n', '[d', '<cmd>lua vim.diagnostic.goto_next()<cr>zz', opts)  -- go to next error
    vim.keymap.set('n', ']d', '<cmd>lua vim.diagnostic.goto_prev()<cr>zz', opts)  -- got to previous error
  end,
})

addServer(
  { name = 'lua-language-server', version = '3.15.0' },
  { 'lua-language-server' },
  { 'lua' },
  { '.luarc.json' },
  { Lua = { workspace = { ignoreDir = { "mason/packages" } }},
})

addServer(
  { name = 'typescript-language-server', version = '5.1.2' },
  { 'typescript-language-server', '--stdio' },
  { 'typescript', 'javascript' }
)

addServer(
  { name = 'prettierd', version = '0.26.2' },
  { 'prettierd' },
  { 'angular', 'css', 'flow', 'graphql', 'html', 'json', 'jsx', 'javascript', 'less', 'markdown', 'scss', 'typescript', 'vue', 'yaml' }
)

addServer({ name = 'jsonlint', version = '1.6.3' }, { 'jsonlint' }, { 'json' })
addServer({ name = 'eslint_d', version = '14.3.0' }, { 'eslint_d' }, { 'typescript', 'javascript' })

enableServers()
