#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

ensure_node
REPO_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
log_info "Installing local npm dependencies..."
npm ci --prefix "$REPO_DIR"

FZF_COMMAND="export FZF_DEFAULT_OPTS='--bind alt-j:down,alt-k:up,ctrl-j:preview-down,ctrl-k:preview-up'"
if ! grep -Fq FZF_DEFAULT_OPTS "${HOME}/.bashrc" 2>/dev/null; then
  log_info "Adding fzf key bindings to ~/.bashrc"
  printf '%s # Custom key bindings for fzf\n' "$FZF_COMMAND" >> "${HOME}/.bashrc"
fi

log_info "Installing global npm tools..."
if ! npm install -g eslint_d @fsouza/prettierd @biomejs/biome; then
  log_warn "Global npm tool installation failed; local dependencies were installed."
fi
log_info "npm phase completed."
