#!/bin/bash
NVIM_VERSION="v0.11.5"
NVIM_ARCHIVE="nvim-linux-x86_64.tar.gz"
INSTALL_ROOT="/opt"
NVIM_URL="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${NVIM_ARCHIVE}"

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
  if ! command -v "${pkg_name}" &> /dev/null; then
    log_info "Ensuring '${pkg_name}' is installed..."
    sudo apt install -y "${pkg_name}" || log_error "Failed to install '${pkg_name}'."
  fi
}

#######################################
## Coexistence Check
#######################################
NVIM_EXEC_NAME="nvim"
IS_CUSTOM=false

if command -v nvim &> /dev/null; then
    echo "--------------------------------------------------------"
    echo "WARNING: An existing Neovim installation was detected."
    echo "To avoid conflicts, choose a name for the new executable."
    echo "Examples: nvim-new, nvim-test, nvim-v011"
    echo "--------------------------------------------------------"
    read -p "Enter new executable name: " USER_EXEC_NAME
    
    if [[ -z "$USER_EXEC_NAME" ]]; then
        log_error "Executable name cannot be empty."
    fi
    NVIM_EXEC_NAME=$USER_EXEC_NAME
    IS_CUSTOM=true
fi

NVIM_DIR="${INSTALL_ROOT}/${NVIM_EXEC_NAME}-dist"

#######################################
## Installing dependencies
#######################################
log_info "Updating APT package lists..."
sudo apt-get update || log_error "Failed to update APT package list."

install_pkg "curl"
install_pkg "git"
install_pkg "gcc"
install_pkg "fzf"
install_pkg "unzip"
install_pkg "fontconfig"
install_pkg "fd-find"
install_pkg "ripgrep"

if ! command -v "npm" &> /dev/null; then
  log_info "npm not found. Installing nodejs now..."
  sudo apt install -y "nodejs" "npm" || log_error "Failed to install 'nodejs'."
fi

#######################################
## Installing Nerd Font
#######################################
log_info "Checking if '${FONT_NAME}' is already installed..."

if fc-list | grep -q "${FONT_NAME}"; then
  log_info "${FONT_NAME} is already installed. Skipping download."
else
  log_info "${FONT_NAME} not found. Proceeding with installation..."
  mkdir -p "${FONT_DIR}"
  curl -fL "${NERD_FONT_URL}" -o "${NERD_FONT_ZIP}" || log_error "Failed to download Nerd Font."
  unzip -o "${NERD_FONT_ZIP}" -d "${FONT_DIR}"
  fc-cache -fv
  rm "${NERD_FONT_ZIP}"
  log_info "Nerd Font installation completed."
fi

#######################################
## Installing Neovim
#######################################
if [ -d "${NVIM_DIR}" ]; then
  log_error "Directory ${NVIM_DIR} already exists. Please remove it to proceed."
fi

log_info "Downloading Neovim ${NVIM_VERSION}..."
curl -fLO "${NVIM_URL}" || log_error "Failed to download Neovim."

log_info "Unpacking Neovim to ${NVIM_DIR}..."
sudo mkdir -p "${NVIM_DIR}"
sudo tar -xzf "${NVIM_ARCHIVE}" -C "${NVIM_DIR}" --strip-components=1
rm "${NVIM_ARCHIVE}"

#######################################
## Creating Isolated Wrapper (NVIM_APPNAME)
#######################################
WRAPPER_PATH="/usr/local/bin/${NVIM_EXEC_NAME}"

if [ "$IS_CUSTOM" = true ]; then
    log_info "Creating isolated executable at ${WRAPPER_PATH}..."
    sudo bash -c "cat > ${WRAPPER_PATH}" <<EOF
#!/bin/bash
# This variable isolates config to ~/.config/${NVIM_EXEC_NAME}
export NVIM_APPNAME="${NVIM_EXEC_NAME}"
exec "${NVIM_DIR}/bin/nvim" "\$@"
EOF
else
    log_info "Creating default symbolic link at ${WRAPPER_PATH}..."
    sudo ln -sf "${NVIM_DIR}/bin/nvim" "${WRAPPER_PATH}"
fi

sudo chmod +x "${WRAPPER_PATH}"

#######################################
## Additional Configs (FZF & NPM)
#######################################
# FZF Config
FZF_COMMAND="export FZF_DEFAULT_OPTS='--bind alt-j:down,alt-k:up,ctrl-j:preview-down,ctrl-k:preview-up'"
if ! grep -q "FZF_DEFAULT_OPTS" ~/.bashrc; then
  log_info "Adding Fzf key bindings to ~/.bashrc"
  echo "${FZF_COMMAND} # Custom key bindings for fzf" >> ~/.bashrc
fi

# NPM Tools
log_info "Installing global NPM packages..."
sudo npm install -g eslint_d @fsouza/prettierd || log_info "NPM install failed, check permissions."

#######################################
## Finalization
#######################################
log_info "Installation completed successfully!"
if [ "$IS_CUSTOM" = true ]; then
    log_info "ISOLATED version installed."
    log_info "Command: ${NVIM_EXEC_NAME}"
    log_info "Config folder: ~/.config/${NVIM_EXEC_NAME}"
    log_info "Data folder: ~/.local/share/${NVIM_EXEC_NAME}"
    mkdir -p "${HOME}/.config/${NVIM_EXEC_NAME}"
else
    log_info "STANDARD version installed."
    log_info "Command: nvim"
fi
