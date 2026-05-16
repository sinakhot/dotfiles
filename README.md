# dotfiles

Personal dotfiles + one-shot machine bootstrap for macOS, Ubuntu/Debian, CachyOS/Arch, and WSL2.

## Quick start

```bash
curl -fsSL https://raw.githubusercontent.com/sinakhot/dotfiles/main/install.sh | bash
```

Or with custom domain (once Pages + DNS configured):

```bash
curl -fsSL https://dotfiles.sinakhot.com/install.sh | bash
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
| Language mgmt | uv (Python), cargo-binstall |
| Editor | neovim (LazyVim) |
| System monitor | btop, dust, duf, procs |
| Data wrangling | jq, yq, gron, miller |
| Task runner | go-task |

### Fish layer

- `fisher` plugin manager
- Default shell set to fish via `chsh`

## Design

Four stages, idempotent — safe to re-run:

1. **Bootstrap** — distro package manager installs git/curl/fish/mise/chezmoi
2. **Dotfiles** — `chezmoi init --apply sinakhot/dotfiles` clones + applies configs
3. **Tools** — `mise install` reads `~/.config/mise/config.toml` and provisions 22 tools as prebuilt binaries
4. **Fish** — fisher + chsh

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

## Editing dotfiles

```bash
chezmoi edit ~/.config/fish/config.fish
chezmoi apply
chezmoi cd               # jump into source dir, git push when ready
```

## License

MIT — see [LICENSE](./LICENSE).
