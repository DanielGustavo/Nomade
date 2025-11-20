# Nomade: Neovim Configuration

This is a personal Neovim configuration designed to be minimalistic, modern, and efficient for setup. It aims to provide a smooth and productive coding experience.

---

## 📦 Plugin Overview

This configuration utilizes several plugins to enhance functionality. Here's a breakdown:

### 📁 File & Navigation

*   **`oil.nvim`**: A powerful file explorer that replaces the default Netrw. It provides a buffer-based interface for navigating directories and performing file operations.
    *   **Keybindings:**
        *   `<leader>e`: Opens the Oil file explorer.
*   **`harpoon`**: Allows you to mark frequently used files and quickly navigate between them.
    *   **Keybindings:**
        *   `<leader>ha`: Adds the current file to the Harpoon list.
        *   `<leader>hs`: Toggles the Harpoon quick menu.
        *   `<leader>0` to `<leader>9`: Selects the Nth marked file.
*   **`fzf-lua`**: Integrates fzf, a fuzzy finder, for efficient searching of files, buffers, commands, and more.
    *   **Keybindings:**
        *   `<leader>f`: Opens fzf file search.
        *   `<leader>ps`: Live grep search.
        *   `<F4>`: LSP code actions.
        *   `<leader>pd`: Document diagnostics.
        *   `<leader>gg`: Git status.
        *   `<leader>gu`: View unmerged git files.

### 🛠️ Core Development & LSP

*   **`mason.nvim`**: Simplifies the installation and management of Language Servers (LSPs), Linters, and Formatters. It ensures that necessary development tools are readily available.
*   **`nvim-treesitter`**: Provides advanced code parsing for improved syntax highlighting, code folding, and semantic analysis. It ensures accurate and context-aware code understanding.
    *   **Configured Languages:** `javascript`, `typescript`, `lua`, `vim`, `vimdoc`, `query`, `markdown`, `markdown_inline`.
*   **`lsp.lua`**: Configures Language Server Protocol (LSP) clients for various languages, enabling features like code completion, go-to-definition, and diagnostics.
    *   **Supported Servers:** `lua-language-server`, `typescript-language-server`, `prettierd`, `jsonlint`, `eslint_d`.
    *   **Keybindings (when LSP is attached):**
        *   `K`: Show hover information.
        *   `gd`: Go to definition.
        *   `gr`: Go to references.
        *   `<leader>rn`: Rename symbol.
        *   `[d`: Go to next diagnostic.
        *   `]d`: Go to previous diagnostic.

### ⌨️ Quality of Life

*   **`mini.pairs`**: Enhances typing by automatically inserting and managing pairs of brackets, parentheses, and quotes.
*   **`nvim-ts-autotag`**: Automatically closes and renames HTML/XML tags, leveraging Treesitter for accurate parsing. This is particularly useful for web development.
*   **`gitsigns.nvim`**: Displays Git status information (lines added, modified, deleted) directly in the sign column, providing immediate feedback on code changes.
    *   **Keybindings:**
        *   `<leader>th`: Preview hunk changes.
        *   `<leader>rh`: Reset hunk changes.

### 🎨 Status Line & Aesthetics

*   **`ellisonleao/gruvbox.nvim`**: Implements the popular Gruvox color scheme, optimized for Neovim.
*   **`lualine.nvim`**: A highly customizable and fast status line plugin that displays important information about the current buffer and Neovim state.

---

## 🚀 Getting Started

1.  **Run the installation script:**

    ```bash
    ./install.sh
    ```

    This script will install Neovim, required dependencies, and a Nerd Font.

2.  **Configure your terminal:**

    After the installation, set a Nerd Font (e.g., "FiraCode Nerd Font") in your terminal emulator settings.

3.  **Source your bashrc:**

    Run `source ~/.bashrc` or restart your terminal after the installation to ensure the Neovim path is set correctly.


## ⚙️ Configuration Options

### General Options (`lua/mysetup/options.lua`)

*   `autoindent`, `smartindent`: Enable smart auto-indentation.
*   `expandtab`, `tabstop = 2`, `shiftwidth = 2`: Configure tab behavior for 2-space indentation.
*   `number`, `relativenumber`: Show absolute and relative line numbers.
*   `swapfile = false`, `backup = false`: Disable swap and backup files.
*   `undodir`, `undofile = true`: Enable persistent undo history.
*   `hlsearch = false`, `incsearch = true`: Disable highlighting for search results but enable incremental search.

### Keybindings (`lua/mysetup/remap.lua`)

*   **Leader Key**: The leader key is set to space (`<leader>`).
*   **File Explorer**: `<leader>e` opens `oil.nvim`.
*   **Buffer Navigation**: `<Tab>` for next buffer, `<S-Tab>` for previous buffer.
*   **Scrolling**: `<C-j>` and `<C-k>` for smoother scrolling, and `zz` to center the screen.
*   **Pasting**: `<leader>p` pastes without yanking.

### Color Scheme (`lua/mysetup/gruvbox.lua`)

*   The `gruvbox` color scheme is applied with various options enabled (e.g., bold, underline, italic emphasis).

---

## ✨ Customization

Feel free to modify the configuration files in `lua/mysetup/` to suit your preferences. You can:

*   Adjust editor options in `options.lua`.
*   Add or modify keybindings in `remap.lua`.
*   Configure plugins by editing their respective files (e.g., `lsp.lua`, `treesitter.lua`).
*   Install additional language servers or tools via `:Mason`.

