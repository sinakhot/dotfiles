# macOS Login Keychain Auto-Unlock — Design

**Date:** 2026-05-20
**Status:** Approved
**Scope:** macOS only. Linux/WSL paths must remain unaffected.

## Goal

On macOS, automatically unlock the login keychain at the start of an
interactive shell, reading the password from a per-machine file
(`~/.config/keychain-pw`) instead of prompting every session. Fall back to the
interactive `security` prompt when no password file exists.

This integrates with the existing fish + chezmoi dotfiles setup and stays
non-destructive to any pre-existing `~/.zshrc`.

## Components

### 1. Auto-unlock script (chezmoi-managed)

**Source:** `home/dot_local/bin/executable_unlock-keychain.sh`
**Applies to:** `~/.local/bin/unlock-keychain.sh` (executable via `executable_` prefix)

```bash
#!/bin/bash
set -euo pipefail
KC="${1:-$HOME/Library/Keychains/login.keychain-db}"
PW_FILE="$HOME/.config/keychain-pw"

if [[ ! -f "$PW_FILE" ]]; then
  echo "no password file at $PW_FILE — falling back to interactive prompt" >&2
  exec security -i unlock-keychain "$KC"
fi

security unlock-keychain -p "$(cat "$PW_FILE")" "$KC"
```

- Default keychain target is the login keychain; first arg can override.
- `~/.local/bin` is already on `PATH` (see `config.fish` `fish_add_path`).

### 2. Fish wiring

Block added inside the existing `if status is-interactive` section of
`home/dot_config/fish/config.fish`, near the keychain (ssh-agent) block:

```fish
# macOS login keychain — auto-unlock from ~/.config/keychain-pw
if test (uname) = Darwin; and test -x ~/.local/bin/unlock-keychain.sh
    ~/.local/bin/unlock-keychain.sh >/dev/null 2>&1
end
```

Guarded on `Darwin` → no-op on Linux/WSL.

### 3. Zsh wiring (non-destructive — option B)

The repo does not manage `~/.zshrc`. Rather than chezmoi-managing the whole
file (which would clobber any existing content), `install.sh` appends a
**grep-guarded** block to `~/.zshrc` so the same script runs in zsh:

```bash
# macOS login keychain — auto-unlock from ~/.config/keychain-pw
if [[ "$(uname)" == "Darwin" && -x ~/.local/bin/unlock-keychain.sh ]]; then
    ~/.local/bin/unlock-keychain.sh >/dev/null 2>&1
fi
```

- Only appended on macOS.
- Idempotent: a sentinel grep (e.g. `unlock-keychain.sh`) prevents duplicate
  appends on re-run.
- Creates `~/.zshrc` if absent; never overwrites existing content.

### 4. install.sh password-prompt stage

A new stage that saves the keychain password once per machine.

- **Guard flag:** `SKIP_KEYCHAIN=1` skips the stage.
- **Platform:** runs only when detected OS is `macos`.
- **Interactivity:** skipped under `NONINTERACTIVE=1` or when stdin is not a TTY
  (keeps CI green).
- **Idempotent:** if `~/.config/keychain-pw` already exists, skip silently.
- **Behavior when missing & interactive:**
  ```bash
  mkdir -p ~/.config
  umask 077
  read -rsp "login keychain password: " PW
  printf "%s" "$PW" > ~/.config/keychain-pw
  chmod 600 ~/.config/keychain-pw
  ```
- The zsh-wiring append (component 3) is performed in this same macOS stage.

Stage ordering: runs after dotfiles are applied (so the script exists at
`~/.local/bin/unlock-keychain.sh`).

### 5. Secrets / documentation

- `~/.config/keychain-pw` is **never committed** (repo is public). It lives only
  on the machine, mode `600`.
- README documents: the one-time save step, that the file is per-machine, and
  the reminder to re-save it after a macOS login-password change.

## Data flow

1. Interactive shell starts (fish or zsh).
2. Wiring block checks `uname == Darwin` and that the script is executable.
3. Script reads `~/.config/keychain-pw`; runs `security unlock-keychain -p`.
4. Missing password file → falls back to interactive `security -i` prompt.

## Error handling

- `set -euo pipefail` in the script.
- Wiring blocks discard stdout/stderr (`>/dev/null 2>&1`) so a failed/missing
  unlock never blocks shell startup.
- `install.sh` stage no-ops on non-macOS, non-interactive, CI, or when the
  password file already exists.

## Testing

- `~/.local/bin/unlock-keychain.sh && echo "unlocked OK"` on a macOS box.
- shellcheck on the script and on `install.sh` (CI `shellcheck` job).
- Re-run `install.sh` to confirm idempotency: no duplicate `~/.zshrc` block, no
  re-prompt when password file exists.
- Linux/WSL: confirm fish/zsh startup unaffected (blocks no-op).

## Out of scope

- Managing `~/.zshrc` wholesale via chezmoi.
- Non-login keychains (overridable via the script's first arg, not automated).
