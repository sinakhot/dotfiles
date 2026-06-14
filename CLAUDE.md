# CLAUDE.md — sinakhot/dotfiles

Instructions for AI agents (Claude Code etc.) working on this repo.

## Purpose

Personal dotfiles + a single-shot machine bootstrap (`install.sh`) that brings a
fresh macOS / Ubuntu / CachyOS / WSL2 box to a known-good shell environment in
one command:

```bash
curl -fsSL https://dotfiles.sinakhot.com/install.sh | bash
```

The script is **idempotent** — safe to re-run on any machine to sync the latest
tool versions + config changes.

## Design

Seven sequential stages in `install.sh`, each guarded by a `SKIP_*` env var:

| Stage | Action | Skip flag |
|---|---|---|
| 1 | Bootstrap system pkgs: `git`, `curl`, `fish`, `gh`, `mise`, `chezmoi` | (always runs) |
| 2 | `chezmoi init --apply sinakhot/dotfiles` → applies `home/dot_config/*` | `SKIP_DOTFILES=1` |
| 3 | `gh auth status` + scopes `repo,read:org,read:packages,gist`; logs in / refreshes if missing | `SKIP_GH_AUTH=1` |
| 4 | `mise install` → all pinned tools as prebuilt binaries (github/aqua backends) | `SKIP_MISE=1` |
| 5 | fisher + `chsh -s fish` | `SKIP_FISH=1` |
| 6 | macOS only: save login-keychain password for `~/.ssh/rc` auto-unlock | `SKIP_KEYCHAIN=1` |
| 7 | AI dev tools: Claude Code, rtk (+ `rtk init -g --auto-patch`), caveman | `SKIP_AI_TOOLS=1` |

**Single source of truth:** `home/dot_config/mise/config.toml` pins every tool
version. One file change → reproducible across every machine.

## Repo layout

```
.
├── install.sh                    # bootstrap script (curl | bash)
├── CNAME                         # GitHub Pages custom domain
├── CLAUDE.md                     # this file
├── README.md                     # human-readable docs (also Pages landing)
├── LICENSE                       # MIT
├── .chezmoiroot                  # tells chezmoi source is home/
├── home/                         # chezmoi source — `dot_X` → `~/.X`
│   ├── private_dot_ssh/
│   │   └── rc                    # → ~/.ssh/rc (700 dir; macOS keychain unlock per SSH session)
│   └── dot_config/
│       ├── fish/config.fish      # → ~/.config/fish/config.fish
│       ├── fish/functions/       # greeting dashboard, helper fns
│       ├── starship.toml         # → ~/.config/starship.toml
│       ├── zellij/config.kdl     # → ~/.config/zellij/config.kdl
│       ├── alacritty/alacritty.toml  # → ~/.config/alacritty/ (catppuccin-macchiato, #010101 bg)
│       ├── yazi/                 # → ~/.config/yazi/
│       ├── nvim/                 # → ~/.config/nvim/
│       └── mise/config.toml      # → ~/.config/mise/config.toml
├── docs/superpowers/             # design specs + implementation plans
└── .github/workflows/
    └── smoke-test.yml            # CI on push/PR/weekly
```

## Adding a new tool

Most tools are mise-managed (preferred). To add one:

1. Find its `ubi` source on GitHub: usually `<org>/<repo>` of the project's
   releases page.
2. Append to `home/dot_config/mise/config.toml`:
   ```toml
   "ubi:<org>/<repo>" = "latest"
   ```
3. Commit. On next `install.sh` run (anywhere), `mise install` picks it up.

If the tool isn't on GitHub or doesn't ship prebuilt binaries:

- Cargo crate → `"cargo:<crate>"` backend
- Aqua-registered → `"aqua:<id>"` backend
- Distro-only → add to `pkg_install` in the bootstrap stage (`install.sh`)

## Adding a new managed config

1. Create file under `home/dot_config/<app>/<file>` in the repo
2. Use chezmoi's `dot_` prefix convention for hidden dirs (e.g. `dot_config`,
   `dot_local`)
3. Commit + push
4. On any target machine: `chezmoi update --apply`

For templating (machine-specific values), rename file to `<name>.tmpl` and use
Go template syntax — chezmoi will render on apply. Avoid templating unless
truly machine-specific; prefer plain files.

## Testing locally before push

```bash
# Dry-run: see what chezmoi would change
chezmoi diff

# Apply only specific file
chezmoi apply ~/.config/fish/config.fish

# Test install.sh against this local working tree (not remote)
SKIP_DOTFILES=1 SKIP_FISH=1 NONINTERACTIVE=1 bash install.sh
```

For full end-to-end test of a branch:

```bash
DOTFILES_BRANCH=my-feature SKIP_FISH=1 NONINTERACTIVE=1 bash install.sh
```

## CI

`.github/workflows/smoke-test.yml` runs on every push, PR, weekly cron, and
manual dispatch. Matrix:

- `ubuntu-bootstrap-only` — Stage 1 only
- `ubuntu-with-dotfiles` — Stage 1 + 2 + 3 (skips fish chsh)
- `arch-bootstrap` — Stage 1 inside `archlinux:latest` container
- `macos-bootstrap` — Stage 1 on macOS runner
- `shellcheck` — lint `install.sh`

CI uses the PR/branch's own copy of `install.sh` and applies the checked-out
working tree directly via `DOTFILES_SOURCE=$GITHUB_WORKSPACE` (chezmoi
`apply --source`, honoring `.chezmoiroot`). This avoids a remote clone, so the
test never depends on `main` being current — nor on the PR branch still
existing on the remote (it may be deleted the instant the PR merges, mid-run).

## Distribution: GitHub Pages + Cloudflare

- **Pages source:** `main` branch, root directory
- **Custom domain:** `dotfiles.sinakhot.com` (set via `CNAME` file)
- **DNS:** Cloudflare CNAME `dotfiles → sinakhot.github.io`, **proxied (orange)**
- **TLS:** Cloudflare universal cert at edge (covers `*.sinakhot.com`)
- **CF SSL mode:** must be `Full (strict)` for the zone — GH Pages serves valid
  cert on its origin

**Two URLs work:**

| URL | Use |
|---|---|
| `https://dotfiles.sinakhot.com/install.sh` | Script (`curl \| bash`) |
| `https://dotfiles.sinakhot.com/` | README rendered as landing page |

GitHub Pages auto-renders `README.md` as `index.html` via Jekyll's default
theme. Don't add `.nojekyll` unless you want raw file serving (would break
README rendering).

## Conventions

- **Bash, not POSIX sh** — `install.sh` uses `[[`, `local`, etc. Shebang
  `#!/usr/bin/env bash`. Don't downgrade to dash/ash.
- **`set -euo pipefail`** at the top. Don't silently swallow errors with `|| true`
  except where genuinely optional (chsh in CI, fisher install warnings).
- **No secrets in this repo.** It's public. SSH keys, tokens, API creds belong
  in a separate private chezmoi data file or out-of-band.
- **Public-safe defaults only.** Anything machine- or identity-specific goes
  behind a chezmoi template guard or a separate private overlay.
- **Symlink the live config back** — when editing the live config under
  `~/.config/<app>`, run `chezmoi re-add` to mirror it into the source.
  Or edit the source directly and `chezmoi apply`.
- **Don't commit `~/.local/share/chezmoi`** (that's the clone). Only this repo
  is source of truth.

## Common ops

```bash
# Edit a managed config (opens source file in $EDITOR, applies on save)
chezmoi edit ~/.config/fish/config.fish

# Add an unmanaged file to chezmoi
chezmoi add ~/.config/<new-file>

# Pull latest from remote + apply
chezmoi update --apply

# Mise: upgrade everything
mise upgrade

# Mise: see what's installed
mise ls

# See drift between live and source
chezmoi diff
```

## When something breaks

| Symptom | Likely cause | Fix |
|---|---|---|
| `install.sh` fails at stage 1 on Ubuntu | Stale apt cache | Re-run; `apt-get update` is included |
| `mise install` fails on one tool | Upstream release naming changed | Check `ubi:<org>/<repo>` releases page, may need explicit version pin |
| `chsh: shell not in /etc/shells` | Fish path not registered | Re-run script; stage 1 registers it |
| `dotfiles.sinakhot.com` 404 | Pages disabled or DNS not propagated | Check `gh api repos/sinakhot/dotfiles/pages` and `dig dotfiles.sinakhot.com` |
| CI passes but local fails | Stale chezmoi clone | `rm -rf ~/.local/share/chezmoi` and re-run |

## Related

- Personal homelab (separate repo, private): `~/Projects/sinakhot/homelab`
- Repo: https://github.com/sinakhot/dotfiles
