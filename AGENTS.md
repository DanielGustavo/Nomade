# Agent Instructions

## Scope

This repository is a Neovim configuration. Keep runtime behavior, installation
behavior, and generated local state distinct when making changes.

## Read The Architecture Reference

Read [`AGENTS_ARCHITECTURE.md`](AGENTS_ARCHITECTURE.md) before any task that:

- refactors the configuration structure or module boundaries;
- changes plugin bootstrapping, Mason, LSP, formatting, Treesitter, or DAP;
- changes `install.sh`, `NVIM_APPNAME`, or runtime paths; or
- changes startup ordering or cross-module dependencies.

That document records the current startup contract, dependency edges, known
drift, and refactor seams. Re-check the implementation when the reference and
the code disagree.

## Work Sequence

1. Inspect `git status --short` before editing. Preserve unrelated worktree
   changes.
2. Trace the relevant entrypoint from `init.lua` or `install.sh` to the module
   or external tool being changed.
3. Make the smallest coherent change. Keep configuration ownership with the
   feature it configures unless the change creates a clear shared boundary.
4. Validate syntax and startup with `nvim --headless '+qa'`; run targeted checks
   for the affected external tool or feature.
5. Run `git diff --check` and inspect `git status --short` after editing.
6. Report the changed files, checks run, and any remaining environment-dependent
   risk.

Completion requires every step above to be accounted for, including a stated
reason when a targeted check cannot run.

## Source Of Truth

- `init.lua` is the startup composition order.
- `lua/mysetup/*.lua` owns runtime feature configuration.
- `plugins.lua` owns the declared plugin checkout list until a refactor changes
  that boundary.
- `install.sh` owns OS-level installation and Neovim distribution setup.
- `mason/` and `pack/` are generated local state and are excluded from Git.
- `README.md` is user-facing documentation; update it when user-visible
  behavior changes, but use the implementation for exact runtime behavior.

## Change Notes

When changing a dependency, path, keymap, startup order, or external command,
update `AGENTS_ARCHITECTURE.md` if its documented contract or risk list is no
longer accurate.
