# Nomade: A Neovim Configuration
A personal, minimalistic, and modern Neovim configuration focused on setup efficiency.

---

## 📦 Installed Plugins

This configuration leverages the following key plugins, organized by function:

### 📁 File & Navigation

| Plugin | Purpose | Dependencies |
| :--- | :--- | :--- |
| **`oil.nvim`** | Provides a buffer-based file explorer (like a specialized Netrw replacement) for navigating directories. | - |
| **`harpoon`** | Quick navigation to frequently used files (marked list). | `nvim-lua/plenary.nvim` (General utility library) |
| **`fzf-lua`** | Powerful fuzzy finder for searching files, buffers, commands, etc. | - |

### 🛠️ Core Development & LSP

| Plugin | Purpose | Notes |
| :--- | :--- | :--- |
| **`mason.nvim`** | Simplifies the management and installation of Language Servers (LSPs), Linters, and Formatters. | Essential for modern code intelligence. |
| **`nvim-treesitter`** | Next-generation incremental parsing system for syntax highlighting, folding, and code analysis. | Crucial for accurate highlighting. |

### ⌨️ Quality of Life

| Plugin | Purpose | Notes |
| :--- | :--- | :--- |
| **`auto-pairs`** | Automatically inserts closing parentheses, brackets, quotes, etc. | Improves typing flow. |
| **`nvim-ts-autotag`** | Automatically closes and renames HTML/XML tags, integrated with Treesitter. | Saves keystrokes in web development. |
| **`gitsigns.nvim`** | Displays Git status information (e.g., lines added, modified, or removed) in the sign column. | Excellent for tracking changes quickly. |

### 🎨 Status Line & Aesthetics

| Plugin | Purpose | Dependencies |
| :--- | :--- | :--- |
| **`ellisonleao/gruvbox.nvim`** | Gruvbox color scheme, rewritten in Lua for Neovim. | - |
| **`lualine.nvim`** | Fast and highly customizable status line. | `nvim-tree/nvim-web-devicons` (Provides icons for file types and status line components). |

