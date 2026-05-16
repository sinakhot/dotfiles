#!/usr/bin/env bash
# sinakhot/dotfiles installer
# Usage:
#   curl -fsSL https://dotfiles.sinakhot.com/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/sinakhot/dotfiles/main/install.sh | bash  # fallback
#
# Idempotent: safe to re-run. Stages skip if already complete.
# Supported platforms: macOS, Ubuntu/Debian, CachyOS/Arch, WSL2 Ubuntu.

set -euo pipefail

# ──────────────────────────────────────────────────────────────
# Overrides (for CI / testing)
#   DOTFILES_REPO    — chezmoi source repo (default: sinakhot/dotfiles)
#   DOTFILES_BRANCH  — branch to apply (default: main)
#   SKIP_DOTFILES=1  — skip chezmoi init/apply stage
#   SKIP_MISE=1      — skip `mise install` stage
#   SKIP_FISH=1      — skip fish post-setup (fisher + chsh)
#   NONINTERACTIVE=1 — don't try chsh (CI runners can't take stdin)
# ──────────────────────────────────────────────────────────────
DOTFILES_REPO="${DOTFILES_REPO:-sinakhot/dotfiles}"
DOTFILES_BRANCH="${DOTFILES_BRANCH:-main}"

# ──────────────────────────────────────────────────────────────
# Colors + branding
# ──────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'
else
    RED=""; GREEN=""; YELLOW=""; BLUE=""; BOLD=""; DIM=""; RESET=""
fi

print_header() {
    cat <<EOF
${BOLD}${BLUE}
   ┌─────────────────────────────────┐
   │   sinakhot/dotfiles installer   │
   └─────────────────────────────────┘
${RESET}
EOF
}

info()  { echo "${BLUE}[i]${RESET} $*"; }
ok()    { echo "${GREEN}[✓]${RESET} $*"; }
warn()  { echo "${YELLOW}[!]${RESET} $*"; }
fail()  { echo "${RED}[✗]${RESET} $*" >&2; exit 1; }

# ──────────────────────────────────────────────────────────────
# Platform detection
# ──────────────────────────────────────────────────────────────
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    elif [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "$ID" in
            ubuntu|debian) echo "ubuntu" ;;
            cachyos|arch|manjaro|endeavouros) echo "arch" ;;
            *) echo "unknown" ;;
        esac
    else
        echo "unknown"
    fi
}

sudo_if_needed() {
    if [[ $EUID -eq 0 ]]; then "$@"; else sudo "$@"; fi
}

pkg_install() {
    case "$OS" in
        macos)
            command -v brew >/dev/null 2>&1 || {
                info "Installing Homebrew…"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            }
            brew install "$@"
            ;;
        ubuntu|wsl)
            sudo_if_needed apt-get update -qq
            sudo_if_needed apt-get install -y "$@"
            ;;
        arch)
            sudo_if_needed pacman -S --noconfirm --needed "$@"
            ;;
        *) fail "Unsupported OS for package install: $OS" ;;
    esac
}

# ──────────────────────────────────────────────────────────────
# Stages
# ──────────────────────────────────────────────────────────────
stage_bootstrap() {
    info "Stage 1/4: bootstrap (git, curl, fish, mise, chezmoi)"
    case "$OS" in
        macos)      pkg_install git curl fish ;;
        ubuntu|wsl) pkg_install git curl ca-certificates build-essential fish ;;
        arch)       pkg_install git curl base-devel fish ;;
    esac

    # Register fish in /etc/shells
    local fish_path
    fish_path="$(command -v fish)"
    if ! grep -qxF "$fish_path" /etc/shells 2>/dev/null; then
        info "Registering fish in /etc/shells"
        echo "$fish_path" | sudo_if_needed tee -a /etc/shells >/dev/null
    fi

    # mise
    if ! command -v mise >/dev/null 2>&1; then
        info "Installing mise…"
        curl -fsSL https://mise.run | sh
    fi
    export PATH="$HOME/.local/bin:$PATH"

    # chezmoi
    if ! command -v chezmoi >/dev/null 2>&1; then
        info "Installing chezmoi…"
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    fi

    ok "Bootstrap layer ready"
}

stage_dotfiles() {
    if [[ "${SKIP_DOTFILES:-0}" == "1" ]]; then
        warn "Stage 2/4: dotfiles SKIPPED (SKIP_DOTFILES=1)"
        return
    fi
    info "Stage 2/4: dotfiles via chezmoi (repo: $DOTFILES_REPO@$DOTFILES_BRANCH)"
    if [[ -d "$HOME/.local/share/chezmoi/.git" ]]; then
        info "chezmoi already initialized; updating…"
        chezmoi update --apply
    else
        chezmoi init --apply --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO"
    fi
    ok "Dotfiles applied"
}

stage_mise() {
    if [[ "${SKIP_MISE:-0}" == "1" ]]; then
        warn "Stage 3/4: mise install SKIPPED (SKIP_MISE=1)"
        return
    fi
    info "Stage 3/4: mise tools"
    if [[ -f "$HOME/.config/mise/config.toml" ]]; then
        mise trust "$HOME/.config/mise/config.toml" || true
        mise install
        ok "Mise tools installed"
    else
        warn "No ~/.config/mise/config.toml yet — skipping (add it via chezmoi)"
    fi
}

stage_fish() {
    if [[ "${SKIP_FISH:-0}" == "1" ]]; then
        warn "Stage 4/4: fish post-setup SKIPPED (SKIP_FISH=1)"
        return
    fi
    info "Stage 4/4: fish post-setup"

    # fisher
    if ! fish -c 'functions -q fisher' 2>/dev/null; then
        info "Installing fisher…"
        fish -c '
            curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
            and fisher install jorgebucaran/fisher
        ' || warn "fisher install failed; install manually"
    fi

    # Default shell
    local fish_path
    fish_path="$(command -v fish)"
    if [[ "${NONINTERACTIVE:-0}" == "1" ]]; then
        info "NONINTERACTIVE=1 — skipping chsh"
    elif [[ "${SHELL:-}" != "$fish_path" ]]; then
        info "Changing default shell to fish"
        if chsh -s "$fish_path"; then
            ok "Shell changed; log out + back in to take effect"
        else
            warn "chsh failed; run manually: chsh -s $fish_path"
        fi
    fi

    ok "Fish configured"
}

# ──────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────
main() {
    print_header

    OS="$(detect_os)"
    info "Detected OS: ${BOLD}$OS${RESET}"
    [[ "$OS" == "unknown" ]] && fail "Unsupported OS"

    stage_bootstrap
    stage_dotfiles
    stage_mise
    stage_fish

    echo
    ok "Setup complete!"
    echo
    info "Next steps:"
    echo "  ${DIM}1.${RESET} Restart terminal or run: ${BOLD}exec fish${RESET}"
    echo "  ${DIM}2.${RESET} Verify tools: ${BOLD}mise ls${RESET}"
    echo "  ${DIM}3.${RESET} Edit a dotfile: ${BOLD}chezmoi edit <file>${RESET}"
    echo "  ${DIM}4.${RESET} Re-run installer anytime to sync: ${BOLD}curl -fsSL https://dotfiles.sinakhot.com/install.sh | bash${RESET}"
    echo
}

main "$@"
