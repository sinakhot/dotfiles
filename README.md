# dotfiles

Personal dotfiles + one-shot machine bootstrap for macOS, Ubuntu/Debian, CachyOS/Arch, and WSL2.

## Quick start

```bash
curl -fsSL https://dotfiles.sinakhot.com/install.sh | bash
```

Fallback (if custom domain ever 404s):

```bash
curl -fsSL https://raw.githubusercontent.com/sinakhot/dotfiles/main/install.sh | bash
```

## What it installs

### Bootstrap layer (system packages)

- `git`, `curl`, `build-essential`
- `fish` — interactive shell
- `mise` — universal version manager
- `chezmoi` — dotfile manager

### Tools (via mise, version-pinned)

| Category | Tools |
|---|---|
| Prompt + multiplexer | starship, zellij |
| Foundation | fzf, zoxide |
| File / search | ripgrep, fd, bat, eza |
| Dev / git | gh, direnv, lazygit, delta |
| Dev containers | devpod |
| Language mgmt | uv (Python), cargo-binstall |
| Editor | neovim (LazyVim) |
| System monitor | btop, dust, duf, procs |
| Data wrangling | jq, yq, gron, miller |
| Task runner | go-task |

### Fish layer

- `fisher` plugin manager
- Default shell set to fish via `chsh`

### AI dev tools

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — Anthropic's terminal coding agent
- [rtk](https://github.com/rtk-ai/rtk) — CLI proxy that filters tool output for 60-90% LLM token savings (auto-hooked into Claude Code via `rtk init -g --auto-patch`)
- [caveman](https://github.com/JuliusBrussee/caveman) — Claude Code skill that compresses responses ~75%

## Design

Seven stages, idempotent — safe to re-run:

1. **Bootstrap** — distro package manager installs git/curl/fish/gh/mise/chezmoi
2. **Dotfiles** — `chezmoi init --apply sinakhot/dotfiles` clones + applies configs
3. **gh auth** — verify `gh auth status` + required scopes (`repo,read:org,read:packages,gist`); runs `gh auth login` / `gh auth refresh` if missing
4. **Tools** — `mise install` reads `~/.config/mise/config.toml` and provisions every pinned tool as a prebuilt binary
5. **Fish** — fisher + chsh
6. **Keychain** (macOS only) — saves the login-keychain password for `~/.ssh/rc` auto-unlock
7. **AI dev tools** — Claude Code + rtk (with `rtk init -g --auto-patch`) + caveman

Single source of truth = `~/.config/mise/config.toml` (managed by chezmoi). One file pins every tool version across every machine.

## Supported platforms

| Platform | Package manager | Notes |
|---|---|---|
| macOS | Homebrew | Auto-installed if missing |
| Ubuntu/Debian | apt | Tested on 22.04+ |
| CachyOS/Arch/Manjaro | pacman | |
| WSL2 (Ubuntu) | apt | Detected via `/proc/version` |

## Updating

```bash
# Re-run installer (pulls latest dotfiles + tool versions)
curl -fsSL https://dotfiles.sinakhot.com/install.sh | bash

# Or pieces separately
chezmoi update --apply   # dotfiles only
mise upgrade             # tools only
```

## macOS login keychain (auto-unlock)

On macOS, the login keychain is unlocked at the start of **every SSH session**
via the chezmoi-managed `~/.ssh/rc` (sshd runs it after auth — any auth method,
interactive or not). One unlock covers everything in that session: the docker
credential helper, ssh-agent / `UseKeychain`, git's osxkeychain helper, Claude
Code, and VS Code Remote-SSH + devcontainers. It reads the password from
`~/.config/keychain-pw` and disables the inactivity auto-lock so long-lived
sessions don't re-lock. `install.sh` prompts to save the password once per
machine.

> Why `~/.ssh/rc` and not a shell hook: SSH sessions each get their own locked
> keychain, and VS Code's server/devcontainer processes aren't started from your
> interactive shell — so a `config.fish`/`.zshrc` hook never reaches them.
> `~/.ssh/rc` runs in every session before the shell or command.

Save the password manually (one-time, per-machine):

```bash
mkdir -p ~/.config
umask 077; read -rsp "login keychain password: " PW; printf "%s" "$PW" > ~/.config/keychain-pw
chmod 600 ~/.config/keychain-pw

# Verify:
~/.local/bin/unlock-keychain.sh && echo "unlocked OK"
```

> `~/.config/keychain-pw` is **per-machine and never committed** (this repo is
> public). Re-save it if you change your macOS login password.

## Editing dotfiles

```bash
chezmoi edit ~/.config/fish/config.fish
chezmoi apply
chezmoi cd               # jump into source dir, git push when ready
```

## Repo layout

```
.
├── install.sh                    # one-shot bootstrap (curl | bash)
├── .chezmoiroot                  # points chezmoi at home/
├── home/                         # chezmoi source dir
│   └── dot_config/
│       ├── fish/config.fish      # → ~/.config/fish/config.fish
│       ├── starship.toml         # → ~/.config/starship.toml
│       ├── zellij/config.kdl     # → ~/.config/zellij/config.kdl
│       └── mise/config.toml      # → ~/.config/mise/config.toml
└── .github/workflows/
    └── smoke-test.yml            # CI: bootstrap on ubuntu/arch/macos + shellcheck
```

`dot_` prefix in source = `.` in $HOME (chezmoi convention).

## Installer env vars (CI / testing)

| Var | Default | Purpose |
|---|---|---|
| `DOTFILES_REPO` | `sinakhot/dotfiles` | chezmoi source repo |
| `DOTFILES_BRANCH` | `main` | branch to apply |
| `SKIP_DOTFILES` | `0` | skip chezmoi init/apply |
| `SKIP_GH_AUTH` | `0` | skip `gh auth status` + scope check |
| `SKIP_MISE` | `0` | skip `mise install` |
| `SKIP_FISH` | `0` | skip fisher + chsh |
| `SKIP_KEYCHAIN` | `0` | skip macOS keychain password save |
| `SKIP_AI_TOOLS` | `0` | skip Claude Code + rtk + caveman install |
| `NONINTERACTIVE` | `0` | don't try chsh / `gh auth login` (CI) |

## License

MIT — see [LICENSE](./LICENSE).
