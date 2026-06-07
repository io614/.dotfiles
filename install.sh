#!/usr/bin/env bash
# dotfiles-setup.sh
# Clones io614/.dotfiles and stows all packages into $HOME via GNU Stow.
# Usage: bash dotfiles-setup.sh [--dry-run] [--restow] [--delete] [packages...]
#
# Examples:
#   bash dotfiles-setup.sh                  # install all packages
#   bash dotfiles-setup.sh --dry-run        # preview what would happen
#   bash dotfiles-setup.sh tmux vim         # only stow tmux and vim
#   bash dotfiles-setup.sh --restow         # re-stow (refreshes symlinks)
#   bash dotfiles-setup.sh --delete tmux    # remove tmux symlinks

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
DOTFILES_REPO="https://github.com/io614/.dotfiles"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
STOW_TARGET="${STOW_TARGET:-$HOME}"

# All known packages in the repo
ALL_PACKAGES=(git sqlite tmux vim)

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[info]${RESET}  $*"; }
ok()      { echo -e "${GREEN}[ok]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[warn]${RESET}  $*"; }
err()     { echo -e "${RED}[error]${RESET} $*" >&2; }
section() { echo -e "\n${BOLD}── $* ──${RESET}"; }

# ── Arg parsing ───────────────────────────────────────────────────────────────
DRY_RUN=false
STOW_ACTION="-S"   # default: stow (install)
REQUESTED_PKGS=()

for arg in "$@"; do
  case "$arg" in
    --dry-run)  DRY_RUN=true ;;
    --restow)   STOW_ACTION="-R" ;;
    --delete)   STOW_ACTION="-D" ;;
    -*)         err "Unknown flag: $arg"; exit 1 ;;
    *)          REQUESTED_PKGS+=("$arg") ;;
  esac
done

# If no packages specified, use all
PACKAGES=("${REQUESTED_PKGS[@]:-${ALL_PACKAGES[@]}}")
# Fallback when REQUESTED_PKGS is empty
if [[ ${#REQUESTED_PKGS[@]} -eq 0 ]]; then
  PACKAGES=("${ALL_PACKAGES[@]}")
fi

STOW_OPTS="$STOW_ACTION --target=$STOW_TARGET --dir=$DOTFILES_DIR"
$DRY_RUN && STOW_OPTS="$STOW_OPTS --simulate"

# ── Dependency check ──────────────────────────────────────────────────────────
section "Checking dependencies"

check_cmd() {
  if command -v "$1" &>/dev/null; then
    ok "$1 found ($(command -v "$1"))"
  else
    warn "$1 not found — installing..."
    if command -v apt-get &>/dev/null; then
      sudo apt-get install -y "$2"
    elif command -v brew &>/dev/null; then
      brew install "$2"
    elif command -v pacman &>/dev/null; then
      sudo pacman -S --noconfirm "$2"
    elif command -v dnf &>/dev/null; then
      sudo dnf install -y "$2"
    else
      err "Cannot auto-install $1. Please install '$2' manually and re-run."
      exit 1
    fi
    ok "$1 installed"
  fi
}

check_cmd git git
check_cmd stow stow

# ── Clone / update ────────────────────────────────────────────────────────────
section "Dotfiles repo"

if [[ -d "$DOTFILES_DIR/.git" ]]; then
  info "Repo already exists at $DOTFILES_DIR — pulling latest..."
  git -C "$DOTFILES_DIR" pull --ff-only
  ok "Up to date"
else
  info "Cloning $DOTFILES_REPO → $DOTFILES_DIR"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  ok "Cloned"
fi

# ── Stow packages ─────────────────────────────────────────────────────────────
section "Stowing packages"

$DRY_RUN && warn "DRY RUN — no changes will be made"

ACTION_LABEL="stow"
[[ "$STOW_ACTION" == "-R" ]] && ACTION_LABEL="restow"
[[ "$STOW_ACTION" == "-D" ]] && ACTION_LABEL="unstow"

FAILED=()
for pkg in "${PACKAGES[@]}"; do
  pkg_dir="$DOTFILES_DIR/$pkg"
  if [[ ! -d "$pkg_dir" ]]; then
    warn "Package '$pkg' not found at $pkg_dir — skipping"
    continue
  fi

  info "${ACTION_LABEL}: ${BOLD}$pkg${RESET}"
  # shellcheck disable=SC2086
  if stow $STOW_OPTS "$pkg" 2>&1; then
    ok "$pkg"
  else
    err "Failed to $ACTION_LABEL '$pkg'"
    FAILED+=("$pkg")
  fi
done

# ── Summary ───────────────────────────────────────────────────────────────────
section "Done"

if [[ ${#FAILED[@]} -gt 0 ]]; then
  err "Some packages failed: ${FAILED[*]}"
  echo -e "\n${YELLOW}Tip:${RESET} If you see 'existing target' errors, a conflicting file already exists."
  echo "      Back it up and re-run, or use --restow to refresh existing symlinks."
  exit 1
else
  if $DRY_RUN; then
    ok "Dry run complete — no files changed"
  else
    ok "All packages ${ACTION_LABEL}ed successfully"
    echo -e "\n${BOLD}Installed packages:${RESET}"
    for pkg in "${PACKAGES[@]}"; do
      [[ -d "$DOTFILES_DIR/$pkg" ]] && echo "  • $pkg → $STOW_TARGET"
    done
    echo ""
    echo "Dotfiles live at: $DOTFILES_DIR"
    echo "Symlinks point to: $STOW_TARGET"
  fi
fi
