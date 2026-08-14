#!/usr/bin/env bash

log_info() {
  printf 'INFO: %s\n' "$1"
}

log_warn() {
  printf 'WARNING: %s\n' "$1" >&2
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

run_privileged() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  elif has_command sudo; then
    sudo "$@"
  else
    die "sudo is required for: $*"
  fi
}

require_command() {
  has_command "$1" || die "Required command is missing: $1"
}

detect_package_manager() {
  local distro_id="" distro_like=""
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    distro_id="${ID:-}"
    distro_like="${ID_LIKE:-}"
  fi

  case " ${distro_id} ${distro_like} " in
    *' debian '*|*' ubuntu '*|*' linuxmint '*)
      has_command apt-get && printf '%s\n' apt-get && return 0 ;;
    *' fedora '*|*' rhel '*|*' centos '*|*' rocky '*|*' alma '*)
      has_command dnf && printf '%s\n' dnf && return 0
      has_command yum && printf '%s\n' yum && return 0 ;;
    *' arch '*) has_command pacman && printf '%s\n' pacman && return 0 ;;
    *' opensuse '*|*' suse '*) has_command zypper && printf '%s\n' zypper && return 0 ;;
    *' alpine '*) has_command apk && printf '%s\n' apk && return 0 ;;
  esac

  die "Could not detect a supported package manager for this Linux distribution."
}

package_name() {
  local manager="$1" package="$2"
  case "${manager}:${package}" in
    apt-get:curl|apt-get:git|apt-get:gcc|apt-get:fzf|apt-get:unzip|apt-get:fontconfig|apt-get:fd-find|apt-get:ripgrep|apt-get:cmake|apt-get:bear|apt-get:tar|apt-get:nodejs|apt-get:npm)
      printf '%s\n' "$package" ;;
    dnf:curl|dnf:git|dnf:gcc|dnf:fzf|dnf:unzip|dnf:fontconfig|dnf:fd-find|dnf:ripgrep|dnf:cmake|dnf:bear|dnf:tar|dnf:nodejs|dnf:npm)
      printf '%s\n' "$package" ;;
    yum:curl|yum:git|yum:gcc|yum:fzf|yum:unzip|yum:fontconfig|yum:fd-find|yum:ripgrep|yum:cmake|yum:bear|yum:tar|yum:nodejs|yum:npm)
      printf '%s\n' "$package" ;;
    pacman:curl|pacman:git|pacman:gcc|pacman:fzf|pacman:unzip|pacman:fontconfig|pacman:ripgrep|pacman:cmake|pacman:bear|pacman:tar|pacman:nodejs|pacman:npm)
      printf '%s\n' "$package" ;;
    pacman:fd-find|zypper:fd-find|apk:fd-find) printf '%s\n' fd ;;
    zypper:curl|zypper:git|zypper:gcc|zypper:fzf|zypper:unzip|zypper:fontconfig|zypper:ripgrep|zypper:cmake|zypper:bear|zypper:tar|zypper:nodejs|zypper:npm)
      printf '%s\n' "$package" ;;
    apk:curl|apk:git|apk:gcc|apk:fzf|apk:unzip|apk:fontconfig|apk:ripgrep|apk:cmake|apk:bear|apk:tar|apk:nodejs|apk:npm)
      printf '%s\n' "$package" ;;
    *) return 1 ;;
  esac
}

install_packages() {
  local manager="$1"
  shift
  local package
  local -a mapped=()
  for package in "$@"; do
    package_mapping="$(package_name "$manager" "$package")" ||
      die "No package mapping for ${package} on ${manager}."
    mapped+=("$package_mapping")
  done

  case "$manager" in
    apt-get)
      run_privileged apt-get update
      run_privileged apt-get install -y "${mapped[@]}" ;;
    dnf|yum) run_privileged "$manager" install -y "${mapped[@]}" ;;
    pacman) run_privileged pacman -Sy --needed --noconfirm "${mapped[@]}" ;;
    zypper) run_privileged zypper --non-interactive install "${mapped[@]}" ;;
    apk) run_privileged apk add "${mapped[@]}" ;;
    *) die "Unsupported package manager: ${manager}." ;;
  esac
}

ensure_packages() {
  local manager="$1"
  shift
  local package
  local -a missing=()
  for package in "$@"; do
    case "$package" in
      fd-find) has_command fdfind || has_command fd || missing+=("$package") ;;
      ripgrep) has_command rg || missing+=("$package") ;;
      gcc) has_command gcc || missing+=("$package") ;;
      nodejs) has_command node || missing+=("$package") ;;
      fontconfig) has_command fc-list || missing+=("$package") ;;
      *) has_command "$package" || missing+=("$package") ;;
    esac
  done
  if [[ "${#missing[@]}" -gt 0 ]]; then
    log_info "Installing missing packages: ${missing[*]}"
    install_packages "$manager" "${missing[@]}"
  fi
}

ensure_node() {
  if has_command node && has_command npm; then
    return 0
  fi
  local manager
  manager="$(detect_package_manager)"
  ensure_packages "$manager" nodejs npm
  require_command node
  require_command npm
}
