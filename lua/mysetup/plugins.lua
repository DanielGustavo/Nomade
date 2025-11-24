local homeDir = os.getenv("HOME")
if not homeDir then
  error("Environment variable $HOME not found. Cannot determine the libraries directory.")
end

local pluginsDir = homeDir .. "/.config/nvim/pack/libs/start"

function getPluginName(plugin)
  local match = string.match(plugin, "[^/]+/(.+)")
  if not match then
    print("Error: Repository format '" .. plugin .. "' must be 'owner/repo_name'.")
    return nil
  end
  return match
end

function mkdir(dir)
  local cmd = 'mkdir -p "' .. dir .. '"'

  vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    print("Error creating directory: " .. dir .. ". Error code: " .. vim.v.shell_error)
    return false
  end
  return true
end

function cloneRepo(plugin, version)
  local libName = getPluginName(plugin)
  if not libName then
    return false
  end

  local url = "https://github.com/" .. plugin .. ".git"
  local targetDir = pluginsDir .. "/" .. libName

  local cmd_parts = { "git clone --depth=1" }

  if version and version ~= "" then
    table.insert(cmd_parts, "--branch")
    table.insert(cmd_parts, version)
  end

  table.insert(cmd_parts, url)
  table.insert(cmd_parts, '"' .. targetDir .. '"')

  local cmd = table.concat(cmd_parts, " ")

  print("Cloning repository " .. plugin .. "...")
  vim.fn.system(cmd)

  if vim.v.shell_error ~= 0 then
    local version_info = version and (" (version: " .. version .. ")") or " (latest version)"
    print("Failed to clone the plugin repository: " .. url .. version_info .. ". Check the name/branch.")
    return false
  else
    vim.cmd("packadd " .. libName)
    print("Cloned successfully: " .. url .. (version and " (version: " .. version .. ")" or " (latest version)"))
    return true
  end
end

function installPlugin(plugin, version)
  local pluginName = getPluginName(plugin)
  if not pluginName then
    return
  end

  if vim.fn.isdirectory(pluginsDir) == 0 then
    print("Plugins directory not found. Attempting to create: " .. pluginsDir)
    local success = mkdir(pluginsDir)
    if not success then
      print("Could not proceed with installation due to base directory creation failure.")
      return
    end
  end

  local pluginPath = pluginsDir .. "/" .. pluginName
  local pluginExists = vim.fn.isdirectory(pluginPath)

  if pluginExists == 0 then
    cloneRepo(plugin, version)
  end
end

installPlugin("stevearc/oil.nvim", "v2.15.0")
installPlugin("nvim-treesitter/nvim-treesitter", "v0.10.0")
installPlugin("windwp/nvim-ts-autotag") -- depends on: nvim-treesitter/nvim-treesitter
installPlugin("mason-org/mason.nvim", "v2.1.0")
installPlugin("ibhagwan/fzf-lua", "0.7")
installPlugin("nvim-lua/plenary.nvim", "v0.1.4")
installPlugin("ThePrimeagen/harpoon", "harpoon2") -- depends on: nvim-lua/plenary.nvim
installPlugin("nvim-lualine/lualine.nvim")        -- depends on: nvim-tree/nvim-web-devicons
installPlugin("nvim-tree/nvim-web-devicons", "v0.100")
installPlugin("lewis6991/gitsigns.nvim", "v1.0.2")
installPlugin("ellisonleao/gruvbox.nvim", "2.0.0")
installPlugin("saghen/blink.cmp", "v1.8.0")
installPlugin("neovim/nvim-lspconfig", "v2.5.0")
installPlugin("mason-org/mason-lspconfig.nvim", "v2.1.0")
installPlugin("windwp/nvim-autopairs", "0.10.0")
installPlugin("stevearc/conform.nvim", "v9.1.0")
installPlugin("neoclide/vim-jsx-improve", "0.0.1")
