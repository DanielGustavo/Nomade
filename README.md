# Nomade: Neovim Configuration

Nomade is a personal Neovim configuration for coding workflows. It uses eager
Lua modules, a small custom Git plugin bootstrap, Mason-managed language tools,
and Neovim 0.11 LSP APIs.

## Installation

Run the interactive installer:

```bash
./install.sh
```

The menu starts with no phases selected. Choose any combination, or choose
`all`. An empty selection exits without changes. Phases can also be run directly
or non-interactively:

```bash
./install.sh system node
scripts/install-nvim.sh --name nvim-test
scripts/install-nvim.sh --force
```

The phases are `system`, `node`, `font`, `nvim`, and `npm`. Each phase is safe to
run independently and installs only its own prerequisites. The `nvim` phase
uses `/opt` and `/usr/local/bin` by default when elevated access is available,
and falls back to user-local paths otherwise. `INSTALL_ROOT`, `BIN_DIR`, and
the corresponding command-line options configure those paths. Existing
Neovim distributions require `--force` to reinstall; existing non-installer
executables are never overwritten.

On first startup, the configuration clones missing plugins at pinned revisions
into Neovim's data directory at `<data>/site/pack/libs/start`, installs the
exact language-tool versions in `mason-packages.json`, and uses the local
TypeScript plugin when available. Plugin and Mason directories are local
generated state and are ignored by Git. The lockfile is validated before Mason
installation; missing, extra, or malformed entries prevent Mason installation.

## Features

### Navigation

`oil.nvim` is the default file explorer:

- `<leader>e`: Open Oil
- `<leader>f`: Find files with fzf-lua
- `<leader>ps`: Live grep
- `<leader>gg`: Git status picker
- `<leader>gu`: List unmerged Git files
- `<leader>ha`: Add the current file to Harpoon
- `<leader>hs`: Toggle the Harpoon menu
- `<leader>0` through `<leader>9`: Select a Harpoon entry

### LSP And Completion

The configured LSP server IDs are:

- `lua_ls`
- `ts_ls`
- `jsonls`
- `eslint`
- `biome` when the project has a `biome.json` or `biome.jsonc` config
- `prismals`
- `tailwindcss`
- `clangd`
- `cmake`
- `pyright` and `ruff` for Python projects
- `jdtls` for Maven and Gradle Java projects

When an LSP client is attached:

- `K`: Show hover information
- `gd`: Go to definition
- `gr`: Go to references
- `<leader>rn`: Rename the symbol
- `[d`: Go to the next diagnostic
- `]d`: Go to the previous diagnostic
- `<F4>`: Show LSP code actions through fzf-lua

`blink.cmp` provides completion from LSP, filesystem paths, snippets, and the
current buffer. Its main completion mappings are `<Tab>` and `<S-Tab>` to move,
`<C-k>` to show or hide, and `<CR>` to accept.

### Syntax, Formatting, And Editing

Treesitter is configured for:

`javascript`, `typescript`, `lua`, `vim`, `vimdoc`, `query`, `markdown`,
`markdown_inline`, `styled`, `c`, `cpp`, `cmake`, `python`, and `java`.

Conform formats on save with:

- JavaScript, JSX, TypeScript, and TSX: `biome` when the project has a Biome
  config, otherwise `prettierd` when the project has a Prettier config
- C and C++: `clang-format` when the project has a `.clang-format` config
- Lua: `stylua` when the project has a `.stylua.toml` or `stylua.toml` config
- Python: `ruff format` when the project has `pyproject.toml`, `ruff.toml`, or
  `uv.lock`
- Java: formatting through nvim-java's JDTLS integration

This repository's Lua style is defined in [`.stylua.toml`](.stylua.toml). Lua
diagnostics are provided by the `lua_ls` language server.

The ESLint language server is likewise started only for projects with an ESLint
config. Biome provides linting when its config is present. No formatter or
linter fallback configuration is used.

`nvim-autopairs` handles bracket and quote pairs. `nvim-ts-autotag` closes and
renames HTML/XML-style tags using Treesitter.

### Python

Python environments are discovered and activated with `venv-selector.nvim`,
including uv-managed `.venv` directories. Use `<leader>pv` to select an
environment manually. Pyright and Ruff provide language diagnostics, and
Ruff formats Python on save.

Pytest is integrated through Neotest:

- `<leader>tt`: Run the nearest test
- `<leader>tf`: Run the current file
- `<leader>to`: Show test output
- `<leader>ts`: Toggle the test summary

Python files can also use an interactive `# %%` cell workflow through
`iron.nvim`:

- `<leader>rr`: Toggle the Python REPL
- `<leader>sf`: Send the current file
- `<leader>sl`: Send the current line
- `<leader>sb`: Send the current code block

Project commands run through the selected environment. Install `pytest` and
any notebook kernel in the project's uv environment; Mason supplies Pyright,
Ruff, and debugpy for editor infrastructure.

### Java

Java projects use `nvim-java`, which configures JDTLS, Java test/debug bundles,
Spring Boot tooling, formatting, running, and runtime switching. It supports
Maven and Gradle projects, including multi-module workspaces.

Useful nvim-java commands include:

- `:JavaTestRunCurrentClass`
- `:JavaTestRunCurrentMethod`
- `:JavaTestDebugCurrentClass`
- `:JavaTestDebugCurrentMethod`
- `:JavaRunnerRunMain`
- `:JavaSettingsChangeRuntime`
- `:JavaRefactorExtractMethod`

Java buffer mappings include:

- `<leader>jb`: Build workspace
- `<leader>jc`: Clean workspace
- `<leader>jr`: Run the main class
- `<leader>tr`: Run the current test method
- `<leader>td`: Debug the current test method
- `<leader>tD`: Debug the current test class

Project scaffolding commands open an interactive terminal:

- `:JavaMavenInit`: Run Maven Archetype generation
- `:JavaGradleInit`: Run `gradle init`
- `:JavaSpringInit`: Generate a Spring Boot project through Spring Initializr

`nvim-java` manages its JDTLS, test/debug, Spring Boot, Lombok, and compatible
JDK tooling separately from Mason. Maven, Gradle, `curl`, and `unzip` remain
system-managed prerequisites for project tasks.

### Git And Debugging

`gitsigns.nvim` displays Git changes and current-line blame:

- `<leader>th`: Preview the current hunk
- `<leader>rh`: Reset the current hunk

The DAP setup targets C and C++ through CodeLLDB; nvim-java configures Java DAP:

- `<leader>DC`: Continue or start debugging
- `<leader>DO`: Step over
- `<leader>DI`: Step into
- `<leader>DQ`: Step out
- `<leader>DB`: Toggle a breakpoint
- `<leader>DU`: Toggle the DAP UI
- `<leader>DE`: Evaluate an expression
- `<leader>DP`: Set the executable path

CodeLLDB is installed through Mason. Its adapter path follows Neovim's data
directory, so alternate `NVIM_APPNAME` installations do not share DAP state.
Python debugging adds a current-file launch configuration using Mason's
debugpy adapter and the selected environment.

### Interface

The Gruvbox colorscheme is enabled with dark background settings. Lualine
provides the statusline and a buffer tabline. A Nerd Font is recommended for
plugin and statusline icons.

## General Settings And Keymaps

The leader key is space. Current editor defaults include:

- Two-space indentation with `expandtab`, `tabstop = 2`, and `shiftwidth = 2`
- Absolute and relative line numbers
- Persistent undo at `~/.vim/undodir`
- Disabled swap and backup files
- Incremental search with search-result highlighting disabled

General mappings include:

- `<leader>d`: Delete the current buffer
- `<Tab>` / `<S-Tab>`: Next / previous buffer outside completion
- `<C-j>` / `<C-k>`: Scroll down / up by one screen line
- `<C-d>` / `<C-u>`: Scroll down / up and center the cursor
- `<leader>p` in visual mode: Paste without overwriting the unnamed register
- `op`, `oi`, and `oo`: Add lines below, above, and below respectively

## Configuration Layout

- `init.lua`: Startup composition order
- `lua/mysetup/options.lua`: Editor options
- `lua/mysetup/remap.lua`: General keymaps
- `lua/mysetup/plugins.lua`: Plugin checkout list and bootstrap
- `lua/mysetup/lsp.lua`: LSP servers and attach keymaps
- `mason-packages.json`: Exact versions for Mason-managed packages
- `lua/mysetup/mason.lua`: Mason root configuration
- `lua/mysetup/treesitter.lua`: Parser and syntax configuration
- `lua/mysetup/formatting.lua`: Conform formatter configuration
- `lua/mysetup/python.lua`: Python environments, tests, and REPL workflow
- `lua/mysetup/autopairs.lua`: Automatic bracket pairing
- Other files in `lua/mysetup/`: Individual plugin configuration
- `install.sh`: Interactive and command-line installation phase dispatcher
- `scripts/install-system.sh`: Base operating-system dependencies
- `scripts/install-node.sh`: Node.js and npm runtime
- `scripts/install-font.sh`: Nerd Font installation
- `scripts/install-nvim.sh`: Neovim distribution and executable wrapper
- `scripts/install-npm.sh`: Local/global npm tooling and fzf shell settings

For architecture, startup ordering, dependencies, and refactor guidance, read
[`AGENTS_ARCHITECTURE.md`](AGENTS_ARCHITECTURE.md).
