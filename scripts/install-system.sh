#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

manager="$(detect_package_manager)"
ensure_packages "$manager" curl git gcc fzf unzip fontconfig fd-find ripgrep cmake bear tar
log_info "System dependencies are ready."
