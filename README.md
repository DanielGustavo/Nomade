# Nomade: Neovim Configuration

Nomade is a personal Neovim configuration for coding workflows. It uses eager
Lua modules, a small custom Git plugin bootstrap, Mason-managed language tools,
and Neovim 0.11 LSP APIs.

## Installation

Run:

```bash
./install.sh
```

The installer installs or verifies the system dependencies, Neovim `v0.11.5`,
FiraCode Nerd Font, Node/npm, the local locked Node dependencies, and the global
`eslint_d` and `prettierd` npm packages. It creates `/usr/local/bin/nvim`
unless another Neovim executable is already present. When another installation
exists, the script asks for a safe custom executable name and creates an
isolated `NVIM_APPNAME` wrapper.

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
- `prismals`
- `tailwindcss`
- `clangd`
- `cmake`

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
`markdown_inline`, `styled`, `c`, `cpp`, and `cmake`.

Conform formats on save with:

- JavaScript and TypeScript: `prettierd`
- C and C++: `clang-format`

`nvim-autopairs` handles bracket and quote pairs. `nvim-ts-autotag` closes and
renames HTML/XML-style tags using Treesitter.

### Git And Debugging

`gitsigns.nvim` displays Git changes and current-line blame:

- `<leader>th`: Preview the current hunk
- `<leader>rh`: Reset the current hunk

The DAP setup targets C and C++ through CodeLLDB:

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
- `lua/mysetup/autopairs.lua`: Automatic bracket pairing
- Other files in `lua/mysetup/`: Individual plugin configuration
- `install.sh`: OS-level installation and Neovim distribution setup

For architecture, startup ordering, dependencies, and refactor guidance, read
[`AGENTS_ARCHITECTURE.md`](AGENTS_ARCHITECTURE.md).
