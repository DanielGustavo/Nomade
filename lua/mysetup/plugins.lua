local pluginsDir = vim.fn.stdpath("data") .. "/site/pack/libs/start"

local function getPluginName(plugin)
  local match = string.match(plugin, "[^/]+/(.+)")
  if not match then
    print("Error: Repository format '" .. plugin .. "' must be 'owner/repo_name'.")
    return nil
  end
  return match
end

local function mkdir(dir)
  return vim.fn.mkdir(dir, "p") == 1
end

local function cloneRepo(plugin, version)
  local libName = getPluginName(plugin)
  if not libName then
    return false
  end

  local url = "https://github.com/" .. plugin .. ".git"
  local targetDir = pluginsDir .. "/" .. libName

  print("Cloning repository " .. plugin .. "...")
  vim.fn.system({ "git", "clone", "--depth=1", url, targetDir })

  if vim.v.shell_error ~= 0 then
    print("Failed to clone the plugin repository: " .. url)
    vim.fn.delete(targetDir, "rf")
    return false
  end

  vim.fn.system({ "git", "fetch", "--depth=1", "origin", version })
  if vim.v.shell_error ~= 0 then
    print("Failed to fetch the pinned plugin revision: " .. version)
    vim.fn.delete(targetDir, "rf")
    return false
  end

  vim.fn.system({ "git", "checkout", "--detach", version })
  if vim.v.shell_error ~= 0 then
    print("Failed to check out the pinned plugin revision: " .. version)
    vim.fn.delete(targetDir, "rf")
    return false
  end

  vim.cmd("packadd " .. libName)
  print("Cloned successfully: " .. url .. " (revision: " .. version .. ")")
  return true
end

local function installPlugin(plugin, version)
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

installPlugin("stevearc/oil.nvim", "975a77cce3c8cb742bc1b3629f4328f5ca977dad")
installPlugin("nvim-treesitter/nvim-treesitter", "42fc28ba918343ebfd5565147a42a26580579482")
installPlugin("windwp/nvim-ts-autotag", "8e1c0a389f20bf7f5b0dd0e00306c1247bda2595")
installPlugin("mason-org/mason.nvim", "ad7146aa61dcaeb54fa900144d768f040090bff0")
installPlugin("ibhagwan/fzf-lua", "47b85a25c0c0b2c20b4e75199ed01bb71e7814f5")
installPlugin("nvim-lua/plenary.nvim", "50012918b2fc8357b87cff2a7f7f0446e47da174")
installPlugin("ThePrimeagen/harpoon", "87b1a3506211538f460786c23f98ec63ad9af4e5")
installPlugin("nvim-lualine/lualine.nvim", "47f91c416daef12db467145e16bed5bbfe00add8")
installPlugin("nvim-tree/nvim-web-devicons", "5b9067899ee6a2538891573500e8fd6ff008440f")
installPlugin("lewis6991/gitsigns.nvim", "7010000889bfb6c26065e0b0f7f1e6aa9163edd9")
installPlugin("ellisonleao/gruvbox.nvim", "61b0b3be2f0cfd521667403a0367298144d6c165")
installPlugin("saghen/blink.cmp", "b19413d214068f316c78978b08264ed1c41830ec")
installPlugin("neovim/nvim-lspconfig", "5bfcc89fd155b4ffc02d18ab3b7d19c2d4e246a7")
installPlugin("mason-org/mason-lspconfig.nvim", "f2fa60409630ec2d24acf84494fb55e1d28d593c")
installPlugin("windwp/nvim-autopairs", "23320e75953ac82e559c610bec5a90d9c6dfa743")
installPlugin("stevearc/conform.nvim", "3543d000dafbc41cc7761d860cfdb24e82154f75")
installPlugin("nvim-neotest/nvim-nio", "21f5324bfac14e22ba26553caf69ec76ae8a7662")
installPlugin("mfussenegger/nvim-dap", "6a5bba0ddea5d419a783e170c20988046376090d")
installPlugin("rcarriga/nvim-dap-ui", "f7d75cca202b52a60c520ec7b1ec3414d6e77b0f")
