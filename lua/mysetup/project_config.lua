local M = {}

local function start_path(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  return name == "" and vim.fn.getcwd() or vim.fs.dirname(name)
end

local function package_has_key(path, key)
  local package_path = vim.fs.find("package.json", {
    upward = true,
    path = path,
    type = "file",
  })[1]

  if not package_path then
    return false
  end

  local ok, package = pcall(vim.json.decode, table.concat(vim.fn.readfile(package_path), "\n"))
  return ok and type(package) == "table" and package[key] ~= nil
end

local function find_config(path, patterns)
  return vim.fs.find(function(name)
    for _, pattern in ipairs(patterns) do
      if vim.regex(pattern):match_str(name) then
        return true
      end
    end
    return false
  end, { upward = true, path = path, type = "file" })
end

function M.has(bufnr, files, package_key)
  local path = start_path(bufnr)
  return #find_config(path, files) > 0
    or (package_key and package_has_key(path, package_key))
end

function M.root(bufnr, files, package_key)
  local path = start_path(bufnr)
  local config_path = find_config(path, files)[1]
  if config_path then
    return vim.fs.dirname(config_path)
  end

  if package_key and package_has_key(path, package_key) then
    local package_path = vim.fs.find("package.json", {
      upward = true,
      path = path,
      type = "file",
    })[1]
    return package_path and vim.fs.dirname(package_path) or nil
  end
end

return M
