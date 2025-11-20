#!/bin/bash
NVIM_VERSION="v0.11.5"
NVIM_ARCHIVE="nvim-linux-x86_64.tar.gz"
NVIM_DIR="/opt/nvim-linux-x86_64"
NVIM_URL="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${NVIM_ARCHIVE}"
NVIM_BIN_PATH="${NVIM_DIR}/bin"

NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip"
NERD_FONT_ZIP="FiraCode.zip"
FONT_DIR="${HOME}/.local/share/fonts"
FONT_NAME="FiraCode Nerd Font"

set -euo pipefail

#######################################
## utils
#######################################
log_info() {
  echo "INFO: $1"
}

log_error() {
  echo "ERROR: $1" >&2
  exit 1
}

install_pkg() {
  local pkg_name="$1"
  log_info "Ensuring '${pkg_name}' is installed..."

  if ! command -v "${pkg_name}" &> /dev/null; then
    log_info "${pkg_name} not found. Installing it now..."
    sudo apt install -y "${pkg_name}" || log_error "Failed to install '${pkg_name}'."
  fi
}
#######################################

#######################################
## installing packages
#######################################
log_info "Updating APT package lists..."
sudo apt-get update || log_error "Failed to update APT package list."

install_pkg "curl"
install_pkg "git"
install_pkg "gcc"
install_pkg "fzf"
install_pkg "unzip"
install_pkg "fontconfig"

if ! command -v "npm" &> /dev/null; then
  log_info "npm not found. Installing nodejs now..."
  sudo apt install -y "nodejs" || log_error "Failed to install 'nodejs'."
fi

log_info "All dependencies installed successfully."
#######################################

#######################################
## installing Nerd Font
#######################################
log_info "Checking if '${FONT_NAME}' is already installed..."

if fc-list | grep "${FONT_NAME}"; then
  log_info "${FONT_NAME} is already installed. Skipping download and installation."
else
  log_info "${FONT_NAME} not found. Proceeding with installation..."

  mkdir -p "${FONT_DIR}" || log_error "Failed to create font directory at ${FONT_DIR}."

  log_info "Downloading Nerd Font from ${NERD_FONT_URL}..."
  curl -fL "${NERD_FONT_URL}" -o "${NERD_FONT_ZIP}" || log_error "Failed to download Nerd Font."

  log_info "Unzipping font files to ${FONT_DIR}..."
  unzip -o "${NERD_FONT_ZIP}" -d "${FONT_DIR}" || log_error "Failed to unzip Nerd Font."

  log_info "Updating font cache..."
  fc-cache -fv || log_error "Failed to update font cache."

  log_info "Cleaning up downloaded font archive..."
  rm "${NERD_FONT_ZIP}" || log_error "Failed to remove temporary font zip file."

  log_info "Nerd Font installation completed."
fi

log_info "Please set a Nerd Font (e.g., '${FONT_NAME}') in your terminal emulator settings."
#######################################

#######################################
## remap fzf keys
#######################################
FZF_COMMAND="export FZF_DEFAULT_OPTS='--bind alt-j:down,alt-k:up,ctrl-j:preview-down,ctrl-k:preview-up'"
FZF_VAR_CHECK="export FZF_DEFAULT_OPTS="

if grep -q "${FZF_VAR_CHECK}" ~/.bashrc; then
  log_info "Avoided adding Fzf config: FZF_DEFAULT_OPTS seems to be already set."
else
  echo "${FZF_COMMAND} # Custom key bindings for fzf" >> ~/.bashrc
  log_info "Fzf key binding configuration completed."
fi
#######################################

#######################################
## install eslint and prettier daemons
#######################################
npm install -g eslint_d
npm install -g @fsouza/prettierd
#######################################

#######################################
## installing nvim
#######################################
log_info "Checking if an nvim instance already exists at: ${NVIM_DIR}"
if [ -d "${NVIM_DIR}" ]; then
  log_error "An nvim instance is already installed at this location. Please remove it first to proceed."
fi

log_info "Downloading Neovim ${NVIM_VERSION}..."
curl -fLO "${NVIM_URL}" || log_error "Failed to download Neovim. Check the URL and network connectivity."

log_info "Unpacking and moving Neovim to ${NVIM_DIR}..."
sudo tar -C /opt -xzf "${NVIM_ARCHIVE}" || log_error "Failed to extract the tar.gz file."

log_info "Cleaning up downloaded archive..."
rm "${NVIM_ARCHIVE}" || log_error "Failed to remove temporary tar.gz file."

log_info "Configuring PATH in ~/.bashrc..."

if grep -q "export PATH=.*${NVIM_BIN_PATH}" ~/.bashrc; then
  log_info "Neovim path already exists in ~/.bashrc. Skipping addition."
else
  echo "export PATH=\"\$PATH:${NVIM_BIN_PATH}\" # Added by Neovim ${NVIM_VERSION} installation script" >> ~/.bashrc
  log_info "Path added. You should run 'source ~/.bashrc' or restart your terminal."
fi

log_info "Neovim installation completed successfully!"
#######################################
