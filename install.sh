#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PHASE_DIR="${SCRIPT_DIR}/scripts"
PHASES=(system node font nvim npm)

usage() {
  cat <<EOF
Usage: $0 [all|phase ...] [nvim options]

Run without arguments to choose phases interactively. Phases are run in this
order: ${PHASES[*]}.

Phases:
  system  Install base operating-system dependencies
  node    Install Node.js and npm
  font    Install FiraCode Nerd Font
  nvim    Install Neovim and its executable wrapper
  npm     Install repository and global npm tools, plus fzf shell settings

The nvim phase accepts --name, --install-root, --bin-dir, and --force.
EOF
}

die() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

phase_script() {
  printf '%s/install-%s.sh' "$PHASE_DIR" "$1"
}

is_phase() {
  local candidate="$1"
  local phase
  for phase in "${PHASES[@]}"; do
    [[ "$candidate" == "$phase" ]] && return 0
  done
  return 1
}

choose_phases() {
  local selection
  printf 'Select phases (numbers separated by spaces, or all):\n' >&2
  local index=1
  local phase
  for phase in "${PHASES[@]}"; do
    printf '  [ ] %d) %s\n' "$index" "$phase" >&2
    ((index += 1))
  done
  printf '  [ ] a) all\n' >&2
  read -r -p 'Selection: ' selection

  [[ -z "$selection" ]] && return 0
  if [[ "$selection" == "all" || "$selection" == "a" ]]; then
    printf '%s\n' all
    return 0
  fi

  local item
  local -a selected=()
  for item in $selection; do
    [[ "$item" =~ ^[1-5]$ ]] || die "Invalid selection: ${item}."
    selected+=("${PHASES[$((item - 1))]}")
  done
  printf '%s\n' "${selected[@]}"
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

declare -a requested=()
declare -a nvim_args=()
if [[ "$#" -eq 0 ]]; then
  mapfile -t requested < <(choose_phases)
else
  while [[ "$#" -gt 0 && "$1" != --* ]]; do
    requested+=("$1")
    shift
  done
  nvim_args=("$@")
fi

if [[ "${requested[0]:-}" == "all" ]]; then
  requested=("${PHASES[@]}")
fi

declare -A selected=()
for argument in "${requested[@]}"; do
  is_phase "$argument" || die "Unknown phase: ${argument}."
  selected["$argument"]=1
done

[[ "${#selected[@]}" -eq 0 ]] && exit 0

[[ "${#nvim_args[@]}" -eq 0 || "${selected[nvim]+yes}" == yes ]] ||
  die "Options are only valid with the nvim phase."
[[ "${#nvim_args[@]}" -eq 0 || "${#selected[@]}" -eq 1 ]] ||
  die "nvim options cannot be combined with other phases."

for phase in "${PHASES[@]}"; do
  [[ "${selected[$phase]+yes}" == yes ]] || continue
  if [[ "$phase" == nvim ]]; then
    "$(phase_script "$phase")" "${nvim_args[@]}"
  else
    [[ "${#nvim_args[@]}" -eq 0 ]] || die "nvim options cannot be used with other phases."
    "$(phase_script "$phase")"
  fi
done
