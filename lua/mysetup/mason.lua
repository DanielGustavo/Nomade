function mkdir(dir)
  local cmd = 'mkdir -p "' .. dir .. '"'

  vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    print("Error creating directory: " .. dir .. ". Error code: " .. vim.v.shell_error)
    return false
  end
  return true
end

local masonDir = os.getenv("HOME") .. "/.config/nvim/mason"
if vim.fn.isdirectory(masonDir) == 0 then
  mkdir(masonDir)
end

require("mason").setup({
  install_root_dir = masonDir
})

vim.api.nvim_create_autocmd("User", {
  pattern = "MasonRegistryUpdateSuccess",
  once = true,
  callback = function()
    local registry = require("mason-registry")
    for _, name in ipairs({ "jdtls", "java-debug-adapter", "google-java-format" }) do
      local ok, pkg = pcall(registry.get_package, name)
      if ok and not pkg:is_installed() then
        pkg:install()
      end
    end
  end,
})

require("mason-registry").refresh()
