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

    # ──────────────────────────────────────────────────────────
    # Abbreviations (expand on space/enter — visible before send)
    # ──────────────────────────────────────────────────────────
    abbr -a z 'zellij attach -c default'
    abbr -a zls 'zellij list-sessions'
    abbr -a zk 'zellij kill-session'

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
    # Greeting — keep quiet
    # ──────────────────────────────────────────────────────────
    set -g fish_greeting ""
end
