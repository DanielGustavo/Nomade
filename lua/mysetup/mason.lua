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
