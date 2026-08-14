#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

NVIM_VERSION="${NVIM_VERSION:-v0.11.5}"
INSTALL_ROOT="${INSTALL_ROOT:-}"
BIN_DIR="${BIN_DIR:-}"
NVIM_EXEC_NAME="${NVIM_EXEC_NAME:-}"
FORCE=false

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --force) FORCE=true ;;
    --name) shift; [[ "$#" -gt 0 ]] || die "--name requires a value."; NVIM_EXEC_NAME="$1" ;;
    --install-root) shift; [[ "$#" -gt 0 ]] || die "--install-root requires a value."; INSTALL_ROOT="$1" ;;
    --bin-dir) shift; [[ "$#" -gt 0 ]] || die "--bin-dir requires a value."; BIN_DIR="$1" ;;
    --version) shift; [[ "$#" -gt 0 ]] || die "--version requires a value."; NVIM_VERSION="$1" ;;
    *) die "Unknown nvim option: $1." ;;
  esac
  shift
done

if [[ -z "$INSTALL_ROOT" ]]; then
  if [[ "${EUID}" -eq 0 ]] || has_command sudo; then
    INSTALL_ROOT=/opt
  else
    INSTALL_ROOT="${HOME}/.local/share/nomade"
  fi
fi
if [[ -z "$BIN_DIR" ]]; then
  if [[ "$INSTALL_ROOT" == /opt* || "$INSTALL_ROOT" == /usr/* ]]; then
    BIN_DIR=/usr/local/bin
  else
    BIN_DIR="${HOME}/.local/bin"
  fi
fi

manager="$(detect_package_manager)"
ensure_packages "$manager" curl tar
require_command uname

if [[ -z "$NVIM_EXEC_NAME" ]]; then
  NVIM_EXEC_NAME=nvim
  if has_command nvim; then
    printf 'An existing Neovim installation was detected.\n'
    read -r -p 'Enter a new executable name: ' NVIM_EXEC_NAME
  fi
fi
[[ "$NVIM_EXEC_NAME" =~ ^[A-Za-z0-9_-]+$ ]] || die "Executable name must contain only letters, numbers, underscores, and hyphens."

case "$(uname -m)" in
  x86_64|amd64) NVIM_ARCHIVE="nvim-linux-x86_64.tar.gz" ;;
  aarch64|arm64) NVIM_ARCHIVE="nvim-linux-arm64.tar.gz" ;;
  armv7l|armv7) NVIM_ARCHIVE="nvim-linux-armv7.tar.gz" ;;
  ppc64le) NVIM_ARCHIVE="nvim-linux-ppc64le.tar.gz" ;;
  riscv64) NVIM_ARCHIVE="nvim-linux-riscv64.tar.gz" ;;
  *) die "No Neovim ${NVIM_VERSION} release artifact is known for $(uname -m)." ;;
esac

NVIM_URL="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${NVIM_ARCHIVE}"
NVIM_DIR="${INSTALL_ROOT}/${NVIM_EXEC_NAME}-dist"
WRAPPER_PATH="${BIN_DIR}/${NVIM_EXEC_NAME}"
archive="$(mktemp --tmpdir "nomade-nvim.XXXXXX.tar.gz")"
trap 'rm -f "$archive"' EXIT

managed_wrapper() {
  [[ -L "$WRAPPER_PATH" && "$(readlink "$WRAPPER_PATH")" == "${NVIM_DIR}/bin/nvim" ]] && return 0
  [[ -f "$WRAPPER_PATH" ]] || return 1
  grep -Fq '# nomade-installer-wrapper' "$WRAPPER_PATH"
}

if [[ -e "$NVIM_DIR" ]]; then
  [[ "$FORCE" == true ]] || die "Directory ${NVIM_DIR} already exists. Use --force to reinstall it."
  log_info "Removing existing Neovim distribution ${NVIM_DIR}."
  run_privileged rm -rf "$NVIM_DIR"
fi
if [[ -e "$WRAPPER_PATH" || -L "$WRAPPER_PATH" ]]; then
  [[ "$FORCE" == true && managed_wrapper ]] || die "${WRAPPER_PATH} already exists; choose another name."
  run_privileged rm -f "$WRAPPER_PATH"
fi

log_info "Downloading Neovim ${NVIM_VERSION}..."
curl -fL "$NVIM_URL" -o "$archive"
run_privileged mkdir -p "$NVIM_DIR"
run_privileged tar -xzf "$archive" -C "$NVIM_DIR" --strip-components=1
run_privileged mkdir -p "$BIN_DIR"

if [[ "$NVIM_EXEC_NAME" == nvim && ! -e "$WRAPPER_PATH" ]]; then
  run_privileged ln -s "${NVIM_DIR}/bin/nvim" "$WRAPPER_PATH"
else
  wrapper_tmp="$(mktemp)"
  trap 'rm -f "$archive" "$wrapper_tmp"' EXIT
  printf '#!/usr/bin/env bash\n# nomade-installer-wrapper\nexport NVIM_APPNAME="%s"\nexec "%s/bin/nvim" "\$@"\n' \
    "$NVIM_EXEC_NAME" "$NVIM_DIR" > "$wrapper_tmp"
  run_privileged install -m 755 "$wrapper_tmp" "$WRAPPER_PATH"
  rm -f "$wrapper_tmp"
fi

if [[ "$NVIM_EXEC_NAME" == nvim ]]; then
  log_info "Installed standard Neovim at ${WRAPPER_PATH}."
else
  mkdir -p "${HOME}/.config/${NVIM_EXEC_NAME}"
  log_info "Installed isolated Neovim command: ${NVIM_EXEC_NAME}."
fi
