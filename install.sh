#!/usr/bin/env bash
#
# Install Oh My Zsh (Linux only), Starship, and copy starship.toml for your shell.
#
# Usage:
#   ./install.sh
#   bash install.sh
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/NeonSpectrum/console-theme/main/install.sh)"
#
set -euo pipefail

REPO_RAW="${REPO_RAW:-https://raw.githubusercontent.com/NeonSpectrum/console-theme/main}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
STARSHIP_TOML_SRC="${SCRIPT_DIR}/starship.toml"
STARSHIP_MARKER="# starship prompt (added by install.sh)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

info()  { printf '%b%s%b\n' "${BLUE}" "$*" "${RESET}"; }
ok()    { printf '%b%s%b\n' "${GREEN}" "$*" "${RESET}"; }
warn()  { printf '%b%s%b\n' "${YELLOW}" "$*" "${RESET}"; }
fail()  { printf '%b%s%b\n' "${RED}" "$*" "${RESET}" >&2; exit 1; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

detect_os() {
  case "$(uname -s)" in
    Linux*)  echo "linux" ;;
    Darwin*) echo "macos" ;;
    *)       echo "unix" ;;
  esac
}

install_oh_my_zsh() {
  local os="$1"
  if [[ "$os" != "linux" ]]; then
    info "Skipping Oh My Zsh (Linux-only step)."
    return 0
  fi

  info "Installing Oh My Zsh..."
  if ! command_exists zsh; then
    warn "Zsh is not installed. Install zsh first, then re-run this script."
    warn "  Debian/Ubuntu: sudo apt install zsh"
    warn "  Fedora:          sudo dnf install zsh"
    warn "  Arch:            sudo pacman -S zsh"
    return 1
  fi

  if [[ -d "${HOME}/.oh-my-zsh" ]]; then
    ok "Oh My Zsh is already installed at ~/.oh-my-zsh"
    return 0
  fi

  if ! command_exists curl; then
    fail "curl is required to install Oh My Zsh. Please install curl and re-run."
  fi

  RUNZSH=no CHSH=no OVERWRITE_CONFIRMATION=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  ok "Oh My Zsh installed successfully."
}

install_starship() {
  info "Installing Starship..."
  if command_exists starship; then
    ok "Starship is already installed ($(starship --version 2>/dev/null || echo 'unknown version'))."
    return 0
  fi

  if ! command_exists curl; then
    fail "curl is required to install Starship. Please install curl and re-run."
  fi

  curl -sS https://starship.rs/install.sh | sh -s -- -y
  ok "Starship installed successfully."

  # Ensure ~/.local/bin is on PATH for this session
  export PATH="${HOME}/.local/bin:${PATH}"
}

copy_starship_config() {
  local config_dir="${HOME}/.config"
  local dest="${config_dir}/starship.toml"
  mkdir -p "$config_dir"

  if [[ -f "$STARSHIP_TOML_SRC" ]]; then
    cp "$STARSHIP_TOML_SRC" "$dest"
    ok "Copied starship.toml to ~/.config/starship.toml"
  else
    info "Downloading starship.toml from ${REPO_RAW}..."
    curl -fsSL "${REPO_RAW}/starship.toml" -o "$dest" \
      || fail "Could not download starship.toml from ${REPO_RAW}"
    ok "Downloaded starship.toml to ~/.config/starship.toml"
  fi
}

append_if_missing() {
  local file="$1"
  local marker="$2"
  local line="$3"

  [[ -f "$file" ]] || touch "$file"
  if grep -qF "$marker" "$file" 2>/dev/null; then
    ok "Starship init already configured in ${file}"
    return 0
  fi

  {
    echo ""
    echo "$marker"
    echo "$line"
  } >> "$file"
  ok "Added Starship init to ${file}"
}

setup_bash() {
  append_if_missing "${HOME}/.bashrc" "$STARSHIP_MARKER" 'eval "$(starship init bash)"'
}

setup_fish() {
  local fish_config="${HOME}/.config/fish/config.fish"
  mkdir -p "$(dirname "$fish_config")"
  append_if_missing "$fish_config" "$STARSHIP_MARKER" "starship init fish | source"
}

setup_zsh() {
  append_if_missing "${HOME}/.zshrc" "$STARSHIP_MARKER" 'eval "$(starship init zsh)"'
}

setup_ion() {
  local ion_config="${HOME}/.config/ion/initrc"
  mkdir -p "$(dirname "$ion_config")"
  append_if_missing "$ion_config" "$STARSHIP_MARKER" 'eval $(starship init ion)'
}

setup_elvish() {
  local elvish_config="${HOME}/.config/elvish/rc.elv"
  mkdir -p "$(dirname "$elvish_config")"
  append_if_missing "$elvish_config" "$STARSHIP_MARKER" 'eval (starship init elvish)'
}

setup_tcsh() {
  append_if_missing "${HOME}/.tcshrc" "$STARSHIP_MARKER" 'eval `starship init tcsh`'
}

setup_nushell() {
  if ! command_exists nu; then
    warn "Nushell (nu) is not installed. Install it from https://www.nushell.sh/ then re-run."
    return 1
  fi

  local autoload_dir
  autoload_dir="$(nu -c '($nu.data-dir | path join "vendor/autoload")' 2>/dev/null)" || {
    warn "Could not determine Nushell data directory."
    return 1
  }

  mkdir -p "$autoload_dir"
  starship init nu > "${autoload_dir}/starship.nu"
  ok "Wrote Starship init to ${autoload_dir}/starship.nu"
}

setup_xonsh() {
  append_if_missing "${HOME}/.xonshrc" "$STARSHIP_MARKER" 'execx($(starship init xonsh))'
}

show_shell_menu() {
  echo "" >&2
  printf '%bSelect your shell:%b\n' "$BOLD" "$RESET" >&2
  echo "  1) Bash" >&2
  echo "  2) Fish" >&2
  echo "  3) Zsh" >&2
  echo "  4) Ion" >&2
  echo "  5) Elvish" >&2
  echo "  6) Tcsh" >&2
  echo "  7) Nushell" >&2
  echo "  8) Xonsh" >&2
  echo "  0) Skip shell configuration" >&2
  echo "" >&2
  printf '%bEnter choice [1-8, 0 to skip]:%b ' "$BOLD" "$RESET" >&2
  read -r choice
  echo "$choice"
}

configure_shell() {
  local choice="$1"
  case "$choice" in
    1) setup_bash ;;
    2) setup_fish ;;
    3) setup_zsh ;;
    4) setup_ion ;;
    5) setup_elvish ;;
    6) setup_tcsh ;;
    7) setup_nushell || warn "Nushell setup failed." ;;
    8) setup_xonsh ;;
    0) warn "Skipped shell configuration." ;;
    *) fail "Invalid choice: ${choice}" ;;
  esac
}

print_success() {
  echo ""
  ok "============================================"
  ok "  Installation completed successfully!"
  ok "============================================"
  echo ""
  info "Next steps:"
  echo "  • Restart your terminal or run: source your shell config file"
  echo "  • Ensure a Nerd Font is enabled in your terminal"
  echo "  • Starship config: ~/.config/starship.toml"
  echo "  • Docs: https://starship.rs/"
  echo ""
}

main() {
  local os
  os="$(detect_os)"

  echo ""
  info "Oh My Zsh + Starship installer"
  info "Detected OS: ${os}"
  echo ""

  install_oh_my_zsh "$os" || warn "Oh My Zsh step finished with warnings."
  install_starship
  copy_starship_config

  local choice
  choice="$(show_shell_menu)"
  configure_shell "$choice"

  print_success
}

main "$@"
