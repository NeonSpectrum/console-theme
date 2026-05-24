#!/usr/bin/env bash
#
# Install Oh My Zsh (Linux only), Starship, and copy starship.toml for your shell.
#
# Usage:
#   ./install.sh
#   bash install.sh
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/NeonSpectrum/console-theme/main/install.sh)"
#   SHELL_CHOICE=3 curl -fsSL .../install.sh | bash   # non-interactive
#   ZSH_PLUGINS=1,2 SHELL_CHOICE=3 curl -fsSL .../install.sh | bash
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

is_interactive() {
  [[ -t 0 ]] || { [[ -r /dev/tty ]] && [[ -w /dev/tty ]]; }
}

read_tty() {
  local __var="${1:?}"
  if [[ -r /dev/tty ]]; then
    IFS= read -r "$__var" </dev/tty
  elif [[ -t 0 ]]; then
    IFS= read -r "$__var"
  else
    fail "Cannot read input: no terminal available. Set SHELL_CHOICE or ZSH_PLUGINS."
  fi
}

is_root() { [[ "$(id -u)" -eq 0 ]]; }

install_zsh() {
  if ! is_root; then
    fail "Zsh is not installed. Re-run with sudo to install it, or install zsh manually:
  Debian/Ubuntu: sudo apt install zsh
  Fedora:          sudo dnf install zsh
  Arch:            sudo pacman -S zsh"
  fi

  info "Zsh not found. Installing zsh..."

  if command_exists apt-get; then
    apt-get update -qq
    apt-get install -y zsh
  elif command_exists apt; then
    apt update -qq
    apt install -y zsh
  elif command_exists dnf; then
    dnf install -y zsh
  elif command_exists pacman; then
    pacman -Sy --noconfirm zsh
  elif command_exists apk; then
    apk add zsh
  elif command_exists zypper; then
    zypper install -y zsh
  elif command_exists yum; then
    yum install -y zsh
  else
    fail "Could not install zsh automatically. Install zsh manually, then re-run this script."
  fi

  command_exists zsh || fail "Zsh installation failed."
  ok "Zsh installed successfully."
}

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
    install_zsh
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

ensure_zsh_installed() {
  if ! command_exists zsh; then
    fail "Zsh is not installed. Re-run with sudo to install it, or install zsh manually:
  Debian/Ubuntu: sudo apt install zsh
  Fedora:          sudo dnf install zsh
  Arch:            sudo pacman -S zsh"
  fi
}

ensure_zshrc() {
  local zshrc="${HOME}/.zshrc"

  if [[ -f "$zshrc" ]]; then
    return 0
  fi

  info "Creating ~/.zshrc..."

  if [[ -d "${HOME}/.oh-my-zsh" ]]; then
    cat >"$zshrc" <<'EOF'
# ~/.zshrc created by install.sh
export ZSH="$HOME/.oh-my-zsh"
plugins=(git)

source $ZSH/oh-my-zsh.sh
EOF
  else
    cat >"$zshrc" <<'EOF'
# ~/.zshrc created by install.sh
EOF
  fi

  ok "Created ~/.zshrc"
}

setup_zsh() {
  ensure_zsh_installed
  ensure_zshrc
  append_if_missing "${HOME}/.zshrc" "$STARSHIP_MARKER" 'eval "$(starship init zsh)"'
  setup_zsh_plugins
}

setup_fish() {
  local fish_config="${HOME}/.config/fish/config.fish"
  mkdir -p "$(dirname "$fish_config")"
  append_if_missing "$fish_config" "$STARSHIP_MARKER" "starship init fish | source"
}

install_zsh_autosuggestions() {
  local plugin_dir="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"

  if [[ -d "$plugin_dir" ]]; then
    ok "zsh-autosuggestions is already installed"
    return 0
  fi

  if ! command_exists git; then
    fail "git is required to install zsh-autosuggestions."
  fi

  info "Installing zsh-autosuggestions..."
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir"
  ok "Installed zsh-autosuggestions"
}

get_zshrc_plugins() {
  local zshrc="${HOME}/.zshrc"
  local plugins_line

  plugins_line="$(grep -E '^plugins=\(' "$zshrc" | head -1 || true)"
  if [[ -z "$plugins_line" ]]; then
    return 0
  fi

  local inner="${plugins_line#plugins=(}"
  inner="${inner%)}"
  local plugin
  for plugin in $inner; do
    [[ -n "$plugin" ]] && echo "$plugin"
  done
}

update_zshrc_plugins() {
  local zshrc="${HOME}/.zshrc"
  local -a plugins=()
  local plugin

  while IFS= read -r plugin; do
    [[ -n "$plugin" ]] && plugins+=("$plugin")
  done < <(get_zshrc_plugins)

  for plugin in "$@"; do
    if [[ " ${plugins[*]:-} " != *" ${plugin} "* ]]; then
      plugins+=("$plugin")
    fi
  done

  if [[ ${#plugins[@]} -eq 0 ]]; then
    return 0
  fi

  local plugins_line="plugins=(${plugins[*]})"

  if grep -qE '^plugins=\(' "$zshrc"; then
    if [[ "$(uname -s)" == Darwin* ]]; then
      sed -i '' "s|^plugins=(.*)|${plugins_line}|" "$zshrc"
    else
      sed -i "s|^plugins=(.*)|${plugins_line}|" "$zshrc"
    fi
  else
    echo "$plugins_line" >>"$zshrc"
  fi

  ok "Updated Oh My Zsh plugins: ${plugins[*]}"
}

show_zsh_plugin_menu() {
  echo "" >&2
  printf '%bSelect Oh My Zsh plugins to install:%b\n' "$BOLD" "$RESET" >&2
  echo "  1) git" >&2
  echo "  2) zsh-autosuggestions" >&2
  echo "  0) Skip" >&2
  echo "" >&2
  printf '%bEnter choices (e.g. 1,2):%b ' "$BOLD" "$RESET" >&2
  read_tty choices
  echo "$choices"
}

resolve_zsh_plugin_choices() {
  if [[ -n "${ZSH_PLUGINS:-}" ]]; then
    echo "$ZSH_PLUGINS"
    return 0
  fi

  if is_interactive; then
    show_zsh_plugin_menu
    return 0
  fi

  echo ""
}

parse_zsh_plugin_choices() {
  local input="${1// /}"
  local -a selected=()
  local part

  [[ -z "$input" || "$input" == "0" ]] && return 0

  IFS=',' read -ra parts <<< "$input"
  for part in "${parts[@]}"; do
    case "$part" in
      1)
        if [[ " ${selected[*]:-} " != *" git "* ]]; then
          selected+=("git")
        fi
        ;;
      2)
        if [[ " ${selected[*]:-} " != *" zsh-autosuggestions "* ]]; then
          selected+=("zsh-autosuggestions")
        fi
        ;;
      *)
        fail "Invalid plugin choice: ${part}"
        ;;
    esac
  done

  local plugin
  for plugin in "${selected[@]}"; do
    echo "$plugin"
  done
}

setup_zsh_plugins() {
  if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
    return 0
  fi

  ensure_zshrc

  local choices plugin
  choices="$(resolve_zsh_plugin_choices)"

  if [[ -z "${choices// /}" || "$choices" == "0" ]]; then
    info "Skipped Oh My Zsh plugin setup."
    return 0
  fi

  local -a plugins=()
  while IFS= read -r plugin; do
    [[ -n "$plugin" ]] && plugins+=("$plugin")
  done < <(parse_zsh_plugin_choices "$choices")

  if [[ ${#plugins[@]} -eq 0 ]]; then
    info "Skipped Oh My Zsh plugin setup."
    return 0
  fi

  for plugin in "${plugins[@]}"; do
    if [[ "$plugin" == "zsh-autosuggestions" ]]; then
      install_zsh_autosuggestions
    fi
  done

  update_zshrc_plugins "${plugins[@]}"
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
    fail "Nushell (nu) is not installed. Install it from https://www.nushell.sh/ then re-run."
  fi

  local autoload_dir
  autoload_dir="$(nu -c '($nu.data-dir | path join "vendor/autoload")' 2>/dev/null)" || \
    fail "Could not determine Nushell data directory."

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
  read_tty choice
  if [[ -z "$choice" ]]; then
    fail "No shell choice entered."
  fi
  echo "$choice"
}

resolve_shell_choice() {
  if [[ -n "${SHELL_CHOICE:-}" ]]; then
    echo "$SHELL_CHOICE"
    return 0
  fi

  if is_interactive; then
    show_shell_menu
    return 0
  fi

  local shell_name
  shell_name="$(basename "${SHELL:-}")"
  case "$shell_name" in
    bash)   echo 1 ;;
    fish)   echo 2 ;;
    zsh)    echo 3 ;;
    ion)    echo 4 ;;
    elvish) echo 5 ;;
    tcsh)   echo 6 ;;
    nu)     echo 7 ;;
    xonsh)  echo 8 ;;
    *)
      fail "Non-interactive install: set SHELL_CHOICE (1-8) or run in an interactive terminal.
Example: SHELL_CHOICE=3 curl -fsSL ${REPO_RAW}/install.sh | bash"
      ;;
  esac
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
    7) setup_nushell ;;
    8) setup_xonsh ;;
    0) info "Skipped shell configuration." ;;
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

  install_oh_my_zsh "$os"
  install_starship
  copy_starship_config

  local choice
  choice="$(resolve_shell_choice)"
  configure_shell "$choice"

  print_success
}

main "$@"
