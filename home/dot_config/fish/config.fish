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

    # keychain — persistent ssh-agent across shells (one agent per boot)
    if command -q keychain
        keychain --quiet id_ed25519
        set -l _kc ~/.keychain/(hostname)-fish
        test -f $_kc; and source $_kc
    end

    # macOS login keychain — auto-unlock from ~/.config/keychain-pw
    if test (uname) = Darwin; and test -x ~/.local/bin/unlock-keychain.sh
        ~/.local/bin/unlock-keychain.sh >/dev/null 2>&1
    end

    # ──────────────────────────────────────────────────────────
    # Abbreviations (expand on space/enter — visible before send)
    # ──────────────────────────────────────────────────────────
    abbr -a z 'zellij attach -c default'
    abbr -a zls 'zellij list-sessions'
    abbr -a zk 'zellij kill-session'
    abbr -a zd 'zellij delete-session'
    abbr -a zda 'zellij delete-all-sessions -y'

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
    # yazi — file manager with cd-on-quit
    # `y` opens yazi fullscreen; on quit, shell cd's to last dir
    # ──────────────────────────────────────────────────────────
    function y
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end

    # ──────────────────────────────────────────────────────────
    # Greeting — tool dashboard (see functions/fish_greeting.fish)
    # ──────────────────────────────────────────────────────────
end
