# Neovim Configuration Architecture

This document describes the current architecture and conventions of the Nomade
Neovim configuration. It is the reference for agents working on architecture,
startup, dependency, and installation changes. The implementation is
authoritative when it differs from this document or `README.md`; update this
reference when a documented contract changes.

## Scope And Goals

This repository is a personal Neovim distribution intended to provide a
minimal, coding-focused environment. It supports JavaScript/TypeScript, Lua,
JSON, Prisma, Tailwind CSS, C/C++, and CMake workflows. The configuration also
contains installation scripts for Neovim, system tools, fonts, language tools,
and plugins.

## Repository Shape

```text
.
├── init.lua                  # Neovim composition root
├── lua/mysetup/              # Eager, side-effect configuration modules
├── install.sh                # OS/tool/font/Neovim bootstrap
├── package.json              # Node development dependency metadata
├── package-lock.json
├── .luarc.json               # Lua language-server/editor settings
├── README.md                 # User-facing feature and setup notes
├── mason/                    # Generated Mason state; ignored by Git
└── pack/libs/start/          # Runtime plugin checkout directory; ignored
```

`pack/libs/start` is generated locally by `lua/mysetup/plugins.lua` and is not
part of the repository. Mason registries and installed language tools are also
local generated state and are ignored by Git.

## Startup Flow

Neovim evaluates `init.lua` in this order:

1. `mysetup.remap` sets the leader and core keymaps.
2. `mysetup.plugins` creates `pack/libs/start`, clones missing plugin
   repositories, and calls `:packadd` for newly cloned plugins.
3. `mysetup.options` applies editor options.
4. `mysetup.mason` creates/configures the local Mason root.
5. `mysetup.lsp` configures capabilities, LSP attach maps, servers, and Mason
   server installation.
6. `mysetup.linter` configures Conform format-on-save.
7. `mysetup.treesitter` configures parsers and highlighting.
8. Feature modules configure Oil, fzf-lua, GitSigns, Harpoon, Lualine,
   autopairs, autotag, the Gruvbox theme, completion, and DAP.
9. `nvim-web-devicons` is initialized directly from `init.lua`.

All modules are loaded eagerly. There is no lazy-loading event model or plugin
specification layer. Ordering in `init.lua` is therefore part of the runtime
contract.

## Module Responsibilities

| Module | Responsibility | Notable side effects/dependencies |
| --- | --- | --- |
| `plugins.lua` | Install and load Git plugins | Shells out to `mkdir` and `git`; defines global helpers; depends on `$HOME` |
| `options.lua` | `vim.opt` editor defaults | Uses `$HOME` for persistent undo directory |
| `remap.lua` | Leader and general navigation/editing maps | Maps `<Tab>` and `<S-Tab>` globally, which also interact with completion |
| `mason.lua` | Configure Mason install root | Defines another global `mkdir`; hard-codes `$HOME/.config/nvim/mason` |
| `lsp.lua` | LSP capabilities, servers, enablement, attach maps | Depends on Blink, Mason, Mason-LSPConfig, and Neovim 0.11 APIs |
| `linter.lua` | Formatters and format-on-save | Uses Conform; formatter binaries are external/Mason or system state |
| `treesitter.lua` | Parser installation and syntax features | Uses the legacy `nvim-treesitter.configs` setup API |
| `completion.lua` | Blink completion behavior | Uses `<Tab>`, `<S-Tab>`, `<C-k>`, and `<CR>` |
| `dap.lua` | C/C++ CodeLLDB debugging and DAP UI | Hard-codes Mason path; prompts once per session for executable |
| `oil.lua` | File explorer behavior and view options | Large plugin-default-shaped configuration |
| `fzf.lua` | Search, grep, diagnostics, Git pickers | Requires `fdfind`, `rg`, and Git; defines a global `getUnmerged` |
| `gitsigns.lua` | Git signs, inline blame, hunk maps | Defines maps before plugin setup; uses Unicode sign glyphs |
| `harpoon.lua` | Marked-file navigation | Requires Harpoon 2 and Plenary |
| `lualine.lua` | Statusline and tabline | Uses Nerd Font glyphs and current window width at startup |
| `pairs.lua` | Automatic bracket pairing | Enables nvim-autopairs defaults |
| `autotag.lua` | HTML/XML tag close and rename | Requires Treesitter and nvim-ts-autotag |
| `gruvbox.lua` | Theme configuration and application | Applies `colorscheme gruvbox` before and after setup |

Modules generally do not return values. A module is an imperative setup script
and is expected to be required once from `init.lua`.

## Dependency Layers

### Bootstrap Layer

`install.sh` installs or verifies system prerequisites, downloads a pinned
Neovim release, installs a Nerd Font, installs global npm tools, and creates a
wrapper or symlink. It can coexist with another Neovim installation by using a
different executable name and `NVIM_APPNAME`.

### Plugin Layer

`plugins.lua` is a custom shallow Git plugin manager. Plugin identity is the
repository name under `pack/libs/start`; versions are passed as Git branches or
tags and cloned with `--depth=1`. Existing directories are treated as already
installed and are not updated or checked out again.

The declared plugin set includes UI/navigation, editing, Treesitter, LSP/Mason,
completion, formatting, Git, and DAP plugins. Some ordering/dependency
assumptions are expressed only as comments in the install list.

### Tooling Layer

Mason is rooted at `~/.config/nvim/mason`. LSP servers are declared in
`lsp.lua`; Mason-LSPConfig receives those server IDs and is asked to ensure the
corresponding tools are installed. The configured server IDs are `lua_ls`,
`ts_ls`, `jsonls`, `eslint`, `prismals`, `tailwindcss`, `clangd`, and `cmake`.
CodeLLDB is used by DAP and is expected in the same Mason root, but is not part
of the LSP server list.

Formatters are configured separately through Conform. `install.sh` installs
`eslint_d` and `prettierd` globally with npm, while C/C++ formatting relies on
`clang-format` being available. This means formatter ownership is split between
system/global npm state and the Neovim config.

## Configuration Patterns

- Plugin modules use `require("plugin").setup({...})` directly at module scope.
- Keymaps are colocated with the feature they control, except general maps in
  `remap.lua` and LSP attach maps in `lsp.lua`.
- Configuration tables are mostly local, but helper functions in
  `plugins.lua`, `mason.lua`, and `fzf.lua` leak into the global Lua namespace.
- Paths are constructed from `$HOME` instead of Neovim's standard data/config
  path APIs.
- Shell commands are assembled as strings and executed through
  `vim.fn.system` or shell commands in the installer.
- Plugin versions are pinned inconsistently: many are tags, some are branches,
  and some have no version at all.
- Feature names are used as module names, but `linter.lua` configures a
  formatter rather than a linter and `pairs.lua` configures autopairs.
- Most maps lack `desc` metadata; DAP maps are the main exception.
- Formatting style is mixed between single and double quotes and between
  compact and expanded table syntax.

## Important Runtime Contracts

- `blink.cmp` must be available before `lsp.lua`, because LSP capabilities are
  built with `blink.cmp.get_lsp_capabilities`.
- `mason.nvim` and `mason-lspconfig.nvim` must be loaded before LSP setup.
- `nvim-nio` must be installed for `nvim-dap-ui`.
- Treesitter must be available for autotag setup and parser behavior.
- The configured DAP adapter path is
  `~/.config/nvim/mason/packages/codelldb/extension/adapter/codelldb`.
- External commands used by the config include `git`, `fdfind`, `rg`, `clangd`,
  `clang-format`, npm-installed `prettierd`/`eslint_d`, and Mason-managed tools.
- Neovim 0.11 behavior is assumed by `vim.lsp.config`, `vim.lsp.enable`, and
  the pinned Neovim version in `install.sh`.

## Known Drift And Refactor Risks

These are observations for planning, not changes made by this document:

- `gruvbox.lua` applies the colorscheme before its setup and then applies it
  again. The second application is the effective one.
- Both `plugins.lua` and `mason.lua` define global `mkdir`; the latter replaces
  the former when startup reaches Mason.
- The plugin bootstrap does not update existing plugins, recover partial clones,
  or make installation atomic. It also shells out during every startup to check
  missing plugin directories.
- `mason.lua` and `dap.lua` assume the standard config path even when
  `install.sh` creates an isolated `NVIM_APPNAME` setup. This can make isolated
  installations share or miss Mason state.
- `<Tab>` and `<S-Tab>` are global buffer navigation maps while Blink also uses
  them for completion selection. Their behavior depends on which mapping is
  active in the current context.
- `package.json` is Node project metadata, not a complete declaration of all
  external tools required by the Neovim configuration.
- Several comments and names contain small documentation inaccuracies, such as
  the DAP UI dependency comment and the `linter.lua` filename.

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
