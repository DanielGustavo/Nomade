#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

FONT_URL="${NERD_FONT_URL:-https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip}"
FONT_DIR="${FONT_DIR:-${HOME}/.local/share/fonts}"
FONT_NAME="${FONT_NAME:-FiraCode Nerd Font}"
archive="$(mktemp --tmpdir "nomade-font.XXXXXX.zip")"
trap 'rm -f "$archive"' EXIT

manager="$(detect_package_manager)"
ensure_packages "$manager" curl unzip fontconfig
require_command fc-list
require_command fc-cache

if fc-list | grep -Fq "$FONT_NAME"; then
  log_info "${FONT_NAME} is already installed."
  exit 0
fi

log_info "Installing ${FONT_NAME}..."
mkdir -p "$FONT_DIR"
curl -fL "$FONT_URL" -o "$archive"
unzip -o "$archive" -d "$FONT_DIR"
fc-cache -f
log_info "Nerd Font installation completed."
