# Neovim Configuration Architecture

This document describes the current architecture and conventions of the Nomade
Neovim configuration. It is the reference for agents working on architecture,
startup, dependency, and installation changes. The implementation is
authoritative when it differs from this document or `README.md`; update this
reference when a documented contract changes.

## Scope And Goals

This repository is a personal Neovim distribution intended to provide a
minimal, coding-focused environment. It supports JavaScript/TypeScript, Lua,
JSON, Prisma, Tailwind CSS, Python, Java, C/C++, and CMake workflows. The configuration also
contains installation scripts for Neovim, system tools, fonts, language tools,
and plugins.

## Repository Shape

```text
.
├── init.lua                  # Neovim composition root
├── lua/mysetup/              # Eager, side-effect configuration modules
├── install.sh                # Installation phase dispatcher
├── scripts/                  # Independently runnable installation phases
├── package.json              # Node development dependency metadata
├── package-lock.json
├── .luarc.json               # Lua language-server/editor settings
├── mason-packages.json       # Tracked Mason package version lockfile
├── README.md                 # User-facing feature and setup notes
├── mason/                    # Generated Mason state under stdpath("data"); ignored
└── pack/libs/start/          # Runtime plugin checkout directory under data; ignored
```

`<data>/site/pack/libs/start` is generated locally by `lua/mysetup/plugins.lua`
and is not part of the repository. Mason registries and installed language tools
are also local generated state and are ignored by Git.

## Startup Flow

Neovim evaluates `init.lua` in this order:

1. `mysetup.remap` sets the leader and core keymaps.
 2. `mysetup.plugins` creates `<data>/site/pack/libs/start`, clones missing
    plugin repositories at pinned revisions, and calls `:packadd` for newly
    cloned plugins.
3. `mysetup.options` applies editor options.
4. `mysetup.mason` creates/configures the app-specific Mason root.
5. `mysetup.completion` configures Blink completion before LSP capabilities are
   built.
6. `mysetup.lsp` configures capabilities, LSP attach maps, servers, Mason
   server installation, and CodeLLDB installation.
7. `mysetup.formatting` configures Conform format-on-save.
8. `mysetup.treesitter` configures parsers and highlighting.
9. `mysetup.python` configures Python environment selection, Neotest, and an
   interactive Python cell REPL.
10. `mysetup.java` configures nvim-java and provides project scaffolding
     commands.
11. Feature modules configure Oil, fzf-lua, GitSigns, Harpoon, Lualine,
    autopairs, autotag, the Gruvbox theme, and DAP.
12. `nvim-web-devicons` is initialized directly from `init.lua`.

All modules are loaded eagerly. There is no lazy-loading event model or plugin
specification layer. Ordering in `init.lua` is therefore part of the runtime
contract.

## Module Responsibilities

| Module | Responsibility | Notable side effects/dependencies |
| --- | --- | --- |
| `plugins.lua` | Install and load Git plugins | Uses `stdpath("data")`; shells out to Git; pins fresh clones to immutable SHAs |
| `options.lua` | `vim.opt` editor defaults | Uses `$HOME` for persistent undo directory |
| `remap.lua` | Leader and general navigation/editing maps | Maps `<Tab>` and `<S-Tab>` globally, which also interact with completion |
| `mason.lua` | Configure Mason install root | Uses the app-specific `stdpath("data")` directory |
| `mason_lock.lua` | Validate Mason package pins and reconcile installed versions | Reads the tracked `mason-packages.json`; uses Mason registry/package receipts |
| `lsp.lua` | LSP capabilities, servers, enablement, attach maps | Depends on Blink, Mason, Mason-LSPConfig, and Neovim 0.11 APIs; delegates Mason package setup to `mason_lock.lua` |
| `formatting.lua` | Formatters and format-on-save | Uses Conform; formatter binaries are external/Mason or system state |
| `python.lua` | Python environments, tests, and REPL | Uses venv-selector, Neotest, and Iron; project commands inherit the selected environment |
| `java.lua` | nvim-java setup, template-backed Java file creation, and Maven/Gradle/Spring scaffolding | Uses nvim-java, template.nvim, Spring Boot Tools, and terminal commands |
| `treesitter.lua` | Parser installation and syntax features | Uses the legacy `nvim-treesitter.configs` setup API |
| `completion.lua` | Blink completion behavior | Uses `<Tab>`, `<S-Tab>`, `<C-k>`, and `<CR>` |
| `dap.lua` | C/C++ CodeLLDB debugging and DAP UI | Uses the app-specific Mason path; prompts once per session for executable |
| `oil.lua` | File explorer behavior and view options | Large plugin-default-shaped configuration |
| `fzf.lua` | Search, grep, diagnostics, Git pickers | Requires `fdfind`, `rg`, and Git; keeps picker helpers local |
| `gitsigns.lua` | Git signs, inline blame, hunk maps | Defines maps before plugin setup; uses Unicode sign glyphs |
| `harpoon.lua` | Marked-file navigation | Requires Harpoon 2 and Plenary |
| `lualine.lua` | Statusline and tabline | Uses Nerd Font glyphs and dynamic window width |
| `autopairs.lua` | Automatic bracket pairing | Enables nvim-autopairs defaults |
| `autotag.lua` | HTML/XML tag close and rename | Requires Treesitter and nvim-ts-autotag |
| `gruvbox.lua` | Theme configuration and application | Applies the configured colorscheme after setup |

Modules generally do not return values. A module is an imperative setup script
and is expected to be required once from `init.lua`.

## Dependency Layers

### Bootstrap Layer

`install.sh` presents an interactive phase checklist when invoked without
arguments and dispatches explicit phase names otherwise. The independently
runnable scripts under `scripts/` provide `system`, `node`, `font`, `nvim`, and
`npm` phases in that canonical order. Each phase ensures only its own runtime
prerequisites, so a single part of the installation can be rerun without
reinstalling the configuration.

The `nvim` phase downloads a pinned Neovim release, creates a system-wide
wrapper or symlink when elevated access is available, and falls back to
user-local paths otherwise. Installation paths are configurable with
environment variables or command-line options. Existing distributions require
`--force`; force only replaces wrappers marked as created by this installer.
The package helper detects `apt-get`, `dnf`, `yum`, `pacman`, `zypper`, or `apk`
using the distribution identity from `/etc/os-release`.

### Plugin Layer

`plugins.lua` is a custom shallow Git plugin manager. Plugin identity is the
repository name under `<data>/site/pack/libs/start`; fresh clones fetch and
check out immutable commit SHAs. Existing directories are treated as already
installed and are not updated or checked out again.

The declared plugin set includes UI/navigation, editing, Treesitter, LSP/Mason,
completion, formatting, Git, and DAP plugins. Some ordering/dependency
assumptions are expressed only as comments in the install list.

### Tooling Layer

Mason is rooted at `<data>/mason`. Exact Mason package versions are declared in
the tracked `mason-packages.json` lockfile. LSP servers are declared in
`lsp.lua`; Mason-LSPConfig receives versioned requests for the corresponding
tools. The configured Mason-managed server IDs are `lua_ls`,
`ts_ls`, `jsonls`, `eslint`, `prismals`, `tailwindcss`, `clangd`, `cmake`,
`pyright`, and `ruff`.
nvim-java owns JDTLS, Java test/debug bundles, Spring Boot Tools, Lombok, and its
compatible JDK through its own package manager. These Java packages are not
duplicated in the Mason lockfile.
Biome is configured separately as an external `biome lsp-proxy` server.
CodeLLDB is also ensured through the Mason registry for DAP, but is not part of
the LSP server list. Startup rejects incomplete, extra, or malformed lockfile
entries and reconciles installed packages whose receipt version differs from the
locked version. Unmanaged Mason packages are left untouched.

Formatters are configured separately through Conform. Java delegates formatting
to JDTLS through nvim-java. Mason manages Stylua,
Ruff, and debugpy for editor infrastructure, while `install.sh` installs
`eslint_d`, `prettierd`, and Biome globally with npm, and C/C++ formatting
relies on `clang-format` being available. Conform only runs the configured
formatter when the project contains that formatter's config; LSP formatting is
not a fallback. The ESLint and Biome servers similarly require their project
config before they start. Lua diagnostics continue to come from `lua_ls`.
Pytest and notebook runtimes remain project dependencies managed by uv.

## Configuration Patterns

- Plugin modules use `require("plugin").setup({...})` directly at module scope.
- Keymaps are colocated with the feature they control, except general maps in
  `remap.lua` and LSP attach maps in `lsp.lua`.
- Configuration tables and helper functions are local to their feature modules.
- Runtime paths use Neovim's standard data/config path APIs.
- Git commands use argument lists through `vim.fn.system`; installer commands
  quote paths and validate user-provided executable names.
- Fresh plugin installs are pinned to immutable commit SHAs.
- Feature module names describe their responsibilities.
- Keymaps use `desc` metadata where configured.
- Touched Lua modules use double quotes and consistent table formatting.

## Important Runtime Contracts

- `blink.cmp` must be available before `lsp.lua`, because LSP capabilities are
  built with `blink.cmp.get_lsp_capabilities`.
- `mason.nvim` and `mason-lspconfig.nvim` must be loaded before LSP setup.
- `nvim-nio` must be installed for `nvim-dap-ui`.
- Treesitter must be available for autotag setup and parser behavior.
- The configured DAP adapter paths are
  `<data>/mason/packages/codelldb/extension/adapter/codelldb` and
  `<data>/mason/packages/debugpy/venv/bin/python`.
- External commands used by the config include `git`, `fdfind`, `rg`, `uv`,
  `clangd`, `clang-format`, `java`, Maven/Gradle, `curl`, `unzip`,
  npm-installed `prettierd`/`eslint_d`/`biome`, and Mason-managed tools.
- Neovim 0.11 behavior is assumed by `vim.lsp.config`, `vim.lsp.enable`, and
  the pinned Neovim version in `install.sh`.

## Known Drift And Refactor Risks

These are observations for planning, not changes made by this document:

- The plugin bootstrap does not update existing plugins, recover partial clones,
  or make installation atomic. It also shells out during every startup to check
  missing plugin directories.
- `<Tab>` and `<S-Tab>` are global buffer navigation maps while Blink also uses
  them for completion selection. Their behavior depends on which mapping is
  active in the current context.
- `package.json` supplies the local TypeScript styled-components plugin; other
  external formatters and language tools remain split between npm, Mason, and
  system packages.

## Suggested Refactor Seams

For a future full refactor, preserve behavior first and introduce boundaries in
this order:

1. Separate plugin declaration/installation from plugin configuration and make
   the plugin list the single source of truth.
2. Centralize paths and runtime directories using Neovim path APIs so standard
   and `NVIM_APPNAME` installations behave consistently.
3. Replace global helper functions with local functions or a small bootstrap
   module.
4. Group core options, global keymaps, autocmds, and plugin feature setup into
   explicit layers while retaining startup ordering.
5. Consolidate language tooling into data-driven server/parser/formatter
   declarations, then generate or apply each subsystem's configuration.
6. Add a headless startup check and targeted smoke checks for plugin loading,
   LSP attachment, formatting, Treesitter, and C/C++ debugging.

These seams are not existing APIs. Current modules expose behavior through side
effects, so moving code requires checking order-sensitive startup behavior.

## Maintenance Contract

Keep this document as a compact reference rather than a second copy of every
configuration value. Record boundaries, ordering, dependency edges, reasons,
and known risks here. Read exact options and plugin versions from the Lua files,
`install.sh`, and the plugin list.

After a refactor, update the affected startup flow, module table, runtime
contracts, and risk entries. A maintenance update is complete when each changed
contract has one authoritative description and the verification commands pass.

## Verification Commands

Useful checks for agents after changes:

```bash
nvim --headless "+checkhealth" "+qa"
nvim --headless "+lua print(vim.inspect(vim.api.nvim_get_runtime_file('', true)))" "+qa"
git status --short
```

For changes involving external tools, also verify the relevant commands with
`command -v` and inspect `:Mason` or the Mason package directory. Do not treat
the presence of `pack/libs/start` or `mason/packages` as repository changes;
both are ignored/generated local state.
