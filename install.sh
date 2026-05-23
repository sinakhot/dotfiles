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
#   SKIP_GH_AUTH=1   — skip gh auth status + scope check
#   SKIP_MISE=1      — skip `mise install` stage
#   SKIP_FISH=1      — skip fish post-setup (fisher + chsh)
#   NONINTERACTIVE=1 — don't try chsh / gh auth login (CI runners can't take stdin)
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
install_gh_ubuntu() {
    # Ubuntu 22.04+ has `gh` in universe; older needs cli.github.com repo.
    if sudo_if_needed apt-get install -y gh 2>/dev/null; then
        return
    fi
    info "Adding cli.github.com apt repo for gh…"
    sudo_if_needed mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo_if_needed tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo_if_needed chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo_if_needed tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo_if_needed apt-get update -qq
    sudo_if_needed apt-get install -y gh
}

stage_bootstrap() {
    info "Stage 1/6: bootstrap (git, curl, fish, gh, mise, chezmoi)"
    case "$OS" in
        macos)      pkg_install git curl fish keychain gh btop eza dust ;;
        ubuntu|wsl)
            pkg_install git curl ca-certificates build-essential fish keychain
            command -v gh >/dev/null 2>&1 || install_gh_ubuntu
            ;;
        arch)       pkg_install git curl base-devel fish keychain github-cli ;;
    esac

    # WSL: wslu provides `wslview` so xdg-open / $BROWSER opens the
    # Windows default browser (e.g. gh OAuth) instead of falling back to lynx.
    [[ "$OS" == "wsl" ]] && pkg_install wslu

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
        warn "Stage 2/6: dotfiles SKIPPED (SKIP_DOTFILES=1)"
        return
    fi
    info "Stage 2/6: dotfiles via chezmoi (repo: $DOTFILES_REPO@$DOTFILES_BRANCH)"
    if [[ -d "$HOME/.local/share/chezmoi/.git" ]]; then
        info "chezmoi already initialized; updating…"
        chezmoi update --apply
    else
        chezmoi init --apply --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO"
    fi
    ok "Dotfiles applied"
}

stage_gh_auth() {
    if [[ "${SKIP_GH_AUTH:-0}" == "1" ]]; then
        warn "Stage 3/6: gh auth SKIPPED (SKIP_GH_AUTH=1)"
        return
    fi
    info "Stage 3/6: gh auth status + scopes"

    if ! command -v gh >/dev/null 2>&1; then
        warn "gh not installed; skipping auth check"
        return
    fi

    local required_scopes=(repo read:org read:packages gist)
    local interactive=1
    [[ "${NONINTERACTIVE:-0}" == "1" || ! -t 0 ]] && interactive=0

    local auth_out
    if ! auth_out="$(gh auth status -h github.com 2>&1)"; then
        if [[ "$interactive" == "0" ]]; then
            warn "gh not authenticated; non-interactive — skipping login"
            info "Run later: gh auth login -h github.com -s $(IFS=,; echo "${required_scopes[*]}")"
            return
        fi
        info "gh not authenticated; running gh auth login…"
        gh auth login -h github.com -s "$(IFS=,; echo "${required_scopes[*]}")" \
            || fail "gh auth login failed"
        auth_out="$(gh auth status -h github.com 2>&1)" || fail "gh auth status failed after login"
    fi

    # Parse "Token scopes: 'a', 'b', 'c'" line.
    # GITHUB_TOKEN env auth (CI) returns no scope line — current_scopes stays empty.
    local scopes_line current_scopes
    scopes_line="$(echo "$auth_out" | grep -E 'Token scopes:' | head -n1 || true)"
    current_scopes="$(echo "$scopes_line" | grep -oE "'[^']+'" | tr -d "'" | tr '\n' ' ' || true)"

    # GitHub scope hierarchy: admin:X ⊇ write:X ⊇ read:X.
    # `repo` umbrella covers repo:status, repo_deployment, public_repo, repo:invite, security_events.
    # `user` covers read:user, user:email, user:follow.
    scope_satisfied() {
        local want="$1" have="$2"
        grep -qw "$want" <<<"$have" && return 0
        case "$want" in
            read:user|user:email|user:follow)
                     grep -qw "user" <<<"$have" && return 0 ;;
            repo:status|repo_deployment|public_repo|repo:invite|security_events)
                     grep -qw "repo" <<<"$have" && return 0 ;;
            read:*)  grep -qwE "write:${want#read:}|admin:${want#read:}" <<<"$have" && return 0 ;;
            write:*) grep -qw "admin:${want#write:}" <<<"$have" && return 0 ;;
        esac
        return 1
    }

    local missing=() s
    for s in "${required_scopes[@]}"; do
        scope_satisfied "$s" "$current_scopes" || missing+=("$s")
    done

    if (( ${#missing[@]} == 0 )); then
        ok "gh authenticated with required scopes"
        return
    fi

    warn "Missing gh scopes: ${missing[*]}"
    if [[ "$interactive" == "0" ]]; then
        info "Run later: gh auth refresh -h github.com -s $(IFS=,; echo "${missing[*]}")"
        return
    fi
    info "Refreshing token to add missing scopes…"
    gh auth refresh -h github.com -s "$(IFS=,; echo "${missing[*]}")" \
        || fail "gh auth refresh failed"
    ok "gh scopes updated"
}

stage_mise() {
    if [[ "${SKIP_MISE:-0}" == "1" ]]; then
        warn "Stage 4/6: mise install SKIPPED (SKIP_MISE=1)"
        return
    fi
    info "Stage 4/6: mise tools"
    if [[ ! -f "$HOME/.config/mise/config.toml" ]]; then
        warn "No ~/.config/mise/config.toml yet — skipping (add it via chezmoi)"
        return
    fi

    mise trust "$HOME/.config/mise/config.toml" || true

    # Auto-export GITHUB_TOKEN from gh CLI if available (avoids rate limit)
    if [[ -z "${GITHUB_TOKEN:-}" ]] && command -v gh >/dev/null 2>&1; then
        local gh_token
        if gh_token="$(gh auth token 2>/dev/null)" && [[ -n "$gh_token" ]]; then
            export GITHUB_TOKEN="$gh_token"
            info "Using GITHUB_TOKEN from gh auth (avoids GitHub rate limit)"
        fi
    fi

    local mise_log
    mise_log="$(mktemp)"
    if mise install 2>&1 | tee "$mise_log"; then
        ok "Mise tools installed"
        rm -f "$mise_log"
        info "Pruning orphaned mise installs…"
        mise prune || warn "mise prune failed (non-fatal)"
        return
    fi

    if grep -qE '403|rate limit|Forbidden' "$mise_log"; then
        warn "mise hit GitHub API rate limit (unauthenticated = 60 req/hr)"
        echo
        if command -v gh >/dev/null 2>&1; then
            echo "  Fix: authenticate gh, then re-run the installer:"
            echo "    ${BOLD}gh auth login${RESET}"
            echo "    ${BOLD}bash install.sh${RESET}   # token auto-exported via gh"
        else
            echo "  Fix: export a GitHub token, then re-run the installer:"
            echo "    ${BOLD}export GITHUB_TOKEN=ghp_xxx${RESET}   # PAT from github.com/settings/tokens"
        fi
        echo
    fi
    rm -f "$mise_log"
    fail "mise install failed"
}

stage_fish() {
    if [[ "${SKIP_FISH:-0}" == "1" ]]; then
        warn "Stage 5/6: fish post-setup SKIPPED (SKIP_FISH=1)"
        return
    fi
    info "Stage 5/6: fish post-setup"

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

stage_keychain() {
    if [[ "${SKIP_KEYCHAIN:-0}" == "1" ]]; then
        warn "Stage 6/6: keychain SKIPPED (SKIP_KEYCHAIN=1)"
        return
    fi
    if [[ "$OS" != "macos" ]]; then
        return
    fi
    info "Stage 6/6: macOS login keychain auto-unlock"

    # Unlocking is wired via the chezmoi-managed ~/.ssh/rc, which sshd runs at
    # the start of every SSH session (any auth method, interactive or not) so
    # keychain-backed tools work over key-based SSH. This stage only saves the
    # per-machine password file that ~/.ssh/rc reads.

    # One-time password save (interactive only).
    if [[ -f "$HOME/.config/keychain-pw" ]]; then
        ok "Keychain password file already present"
        return
    fi
    if [[ "${NONINTERACTIVE:-0}" == "1" || ! -t 0 ]]; then
        warn "No ~/.config/keychain-pw and not interactive — skipping prompt"
        info "Save it later: read -rs into ~/.config/keychain-pw (chmod 600)"
        return
    fi
    info "Save your macOS login keychain password (stored per-machine, mode 600)"
    mkdir -p "$HOME/.config"
    ( umask 077
      read -rsp "login keychain password: " PW
      printf "%s" "$PW" > "$HOME/.config/keychain-pw" )
    chmod 600 "$HOME/.config/keychain-pw"
    echo
    ok "Saved ~/.config/keychain-pw"
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
    stage_gh_auth
    stage_mise
    stage_fish
    stage_keychain

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
