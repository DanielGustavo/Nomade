local lockfile_path = vim.fn.stdpath("config") .. "/mason-packages.json"

local function notify(message, level)
  vim.notify(message, level, { title = "Mason" })
end

local function invalid(message)
  notify(("Invalid %s: %s"):format(lockfile_path, message), vim.log.levels.ERROR)
end

local function load(expected_packages)
  local file = io.open(lockfile_path, "r")
  if not file then
    invalid("file is missing")
    return nil
  end

  local contents = file:read("*a")
  file:close()

  local ok, packages = pcall(vim.json.decode, contents)
  if not ok or type(packages) ~= "table" or vim.islist(packages) then
    invalid("expected a JSON object mapping package names to versions")
    return nil
  end

  for package_name, version in pairs(packages) do
    if type(package_name) ~= "string" or type(version) ~= "string" or version == "" then
      invalid("package names and versions must be non-empty strings")
      return nil
    end
    if not expected_packages[package_name] then
      invalid(("unexpected package %q"):format(package_name))
      return nil
    end
  end

  for package_name in pairs(expected_packages) do
    if packages[package_name] == nil then
      invalid(("missing package %q"):format(package_name))
      return nil
    end
  end

  return packages
end

local function versioned_specs(servers, package_versions, mappings)
  local specs = {}
  for server_name in pairs(servers) do
    local package_name = mappings.lspconfig_to_package[server_name]
    specs[#specs + 1] = ("%s@%s"):format(server_name, package_versions[package_name])
  end
  return specs
end

local function reconcile_installed(package_versions, registry)
  for package_name, expected_version in pairs(package_versions) do
    local ok, package = pcall(registry.get_package, package_name)
    if not ok then
      notify(("Package %q is unavailable in the Mason registry"):format(package_name), vim.log.levels.ERROR)
    elseif package:is_installed() and package:get_installed_version() ~= expected_version then
      package:uninstall({}, function(success, err)
        if not success then
          notify(("Could not replace %s: %s"):format(package_name, err), vim.log.levels.ERROR)
          return
        end

        package:install({ version = expected_version }, function(install_success, install_err)
          if not install_success then
            notify(
              ("Could not install %s@%s: %s"):format(package_name, expected_version, install_err),
              vim.log.levels.ERROR
            )
          end
        end)
      end)
    end
  end
end

local function install_missing(package_versions, registry)
  for package_name, expected_version in pairs(package_versions) do
    local ok, package = pcall(registry.get_package, package_name)
    if not ok then
      notify(("Package %q is unavailable in the Mason registry"):format(package_name), vim.log.levels.ERROR)
    elseif not package:is_installed() and not package:is_installing() then
      package:install({ version = expected_version }, function(success, err)
        if not success then
          notify(("Could not install %s@%s: %s"):format(package_name, expected_version, err), vim.log.levels.ERROR)
        end
      end)
    end
  end
end

local function setup(servers, additional_package_names)
  local mason_lspconfig = require("mason-lspconfig")
  local mason_mappings = mason_lspconfig.get_mappings()
  local expected_packages = {}

  for server_name in pairs(servers) do
    expected_packages[mason_mappings.lspconfig_to_package[server_name]] = true
  end
  for _, package_name in ipairs(additional_package_names) do
    expected_packages[package_name] = true
  end

  local package_versions = load(expected_packages)
  mason_lspconfig.setup({
    ensure_installed = package_versions and versioned_specs(servers, package_versions, mason_mappings) or {},
    automatic_enable = false,
  })

  if not package_versions or vim.tbl_contains(vim.v.argv, "--headless") then
    return
  end

  local registry = require("mason-registry")
  registry.refresh(function(success)
    if not success then
      notify("Could not refresh the Mason registry", vim.log.levels.WARN)
      return
    end

    reconcile_installed(package_versions, registry)

    install_missing(package_versions, registry)
  end)
end

return setup
