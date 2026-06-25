# ~/.config/fish/config.fish — managed by chezmoi (sinakhot/dotfiles)

# ──────────────────────────────────────────────────────────────
# PATH — prepend user bins before system
# ──────────────────────────────────────────────────────────────
fish_add_path -gP \
    $HOME/.local/bin \
    $HOME/.cargo/bin \
    /opt/homebrew/bin \
    /home/linuxbrew/.linuxbrew/bin

# ──────────────────────────────────────────────────────────────
# Editor — neovim everywhere
# ──────────────────────────────────────────────────────────────
set -gx EDITOR nvim
set -gx VISUAL nvim

# ──────────────────────────────────────────────────────────────
# WSL — open URLs in the Windows default browser (Chrome) via wslview
# Prevents gh / xdg-open falling back to lynx on headless WSL
# ──────────────────────────────────────────────────────────────
if set -q WSL_DISTRO_NAME; and command -q wslview
    set -gx BROWSER wslview
end

# ──────────────────────────────────────────────────────────────
# Kubernetes — default to the user kubeconfig when present.
# On k3s nodes, `kubectl` is a wrapper that otherwise defaults to the
# root-owned /etc/rancher/k3s/k3s.yaml (permission denied for non-root);
# pointing KUBECONFIG at ~/.kube/config makes bare `kubectl` use it.
# ──────────────────────────────────────────────────────────────
if test -f $HOME/.kube/config
    set -gx KUBECONFIG $HOME/.kube/config
end

# ──────────────────────────────────────────────────────────────
# Interactive-only setup
# ──────────────────────────────────────────────────────────────
if status is-interactive
    # mise — version manager activation (handles tool shims + env vars)
    if command -q mise
        mise activate fish | source
    end

    # starship — prompt
    if command -q starship
        starship init fish | source
    end

    # zoxide — smarter cd
    if command -q zoxide
        zoxide init fish --cmd cd | source
    end

    # direnv — per-dir env
    if command -q direnv
        direnv hook fish | source
    end

    # keychain — persistent ssh-agent across shells (one agent per boot).
    # `--noask` keeps shell start silent: encrypted keys are skipped instead
    # of prompting. Listing keys is still required so keychain writes the
    # env file (~/.keychain/<host>-fish) — without a key arg new shells lose
    # SSH_AUTH_SOCK when the originating shell exits. Load encrypted keys
    # manually once per boot: `ssh-add ~/.ssh/<key>`.
    if command -q keychain
        keychain --quiet --noask id_ed25519
        set -l _kc ~/.keychain/(hostname)-fish
        test -f $_kc; and source $_kc
    end

    # ──────────────────────────────────────────────────────────
    # Abbreviations (expand on space/enter — visible before send)
    # ──────────────────────────────────────────────────────────
    abbr -a h 'herdr'
    abbr -a hls 'herdr session list'
    abbr -a hk 'herdr session stop'
    abbr -a hss 'herdr server stop'

    abbr -a g git
    abbr -a gs 'git status'
    abbr -a gd 'git diff'
    abbr -a gl 'git log --oneline --graph --decorate'
    abbr -a lg lazygit

    abbr -a k kubectl
    abbr -a kgp 'kubectl get pods'
    abbr -a kgs 'kubectl get svc'

    abbr -a cm chezmoi
    abbr -a cma 'chezmoi apply'
    abbr -a cme 'chezmoi edit'

    abbr -a ll 'eza -lah --git'
    abbr -a lt 'eza --tree --level=2'
    abbr -a cat bat

    abbr -a vim nvim
    abbr -a vi nvim

    # ──────────────────────────────────────────────────────────
    # Greeting — tool dashboard (see functions/fish_greeting.fish)
    # ──────────────────────────────────────────────────────────
end
