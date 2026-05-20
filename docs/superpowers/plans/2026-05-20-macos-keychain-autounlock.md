# macOS Login Keychain Auto-Unlock Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Auto-unlock the macOS login keychain at interactive shell startup using a per-machine password file, with fish + zsh wiring and a one-time prompt in `install.sh`.

**Architecture:** A chezmoi-managed script (`~/.local/bin/unlock-keychain.sh`) reads `~/.config/keychain-pw` and runs `security unlock-keychain`. Fish wiring lives in the managed `config.fish`. Zsh wiring is appended idempotently to `~/.zshrc` by `install.sh` (non-destructive). A new macOS-only, interactive-only `install.sh` stage prompts once to save the password. Every piece guards on `Darwin`, so Linux/WSL is untouched.

**Tech Stack:** bash, fish, chezmoi, macOS `security` CLI, shellcheck.

---

## File Structure

- Create: `home/dot_local/bin/executable_unlock-keychain.sh` — the unlock script (chezmoi source; applies to `~/.local/bin/unlock-keychain.sh`, executable).
- Modify: `home/dot_config/fish/config.fish` — add Darwin-guarded auto-unlock block inside `status is-interactive`.
- Modify: `install.sh` — add `stage_keychain` (macOS-only password prompt + idempotent zsh wiring); renumber stage labels to `/5`; call it in `main`.
- Modify: `README.md` — document the one-time per-machine password step.

No automated test framework exists in this repo (it is dotfiles). Verification is via `shellcheck`, `chezmoi diff`/`apply`, and idempotency re-runs. Tasks use that as the "test" step.

---

## Task 1: Create the chezmoi-managed unlock script

**Files:**
- Create: `home/dot_local/bin/executable_unlock-keychain.sh`

- [ ] **Step 1: Write the script**

Create `home/dot_local/bin/executable_unlock-keychain.sh` with exactly:

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

- [ ] **Step 2: Lint the script**

Run: `shellcheck home/dot_local/bin/executable_unlock-keychain.sh`
Expected: no errors (exit 0). `security` is a macOS binary; shellcheck does not flag unknown external commands.

- [ ] **Step 3: Commit**

```bash
git add home/dot_local/bin/executable_unlock-keychain.sh
git commit -m "feat: add macOS keychain auto-unlock script (chezmoi-managed)"
```

---

## Task 2: Wire auto-unlock into fish

**Files:**
- Modify: `home/dot_config/fish/config.fish` (inside `if status is-interactive`, after the keychain ssh-agent block ending at line 47)

- [ ] **Step 1: Add the Darwin-guarded block**

In `home/dot_config/fish/config.fish`, immediately after the existing keychain block (the `end` on line 47, before the Abbreviations comment), insert:

```fish

    # macOS login keychain — auto-unlock from ~/.config/keychain-pw
    if test (uname) = Darwin; and test -x ~/.local/bin/unlock-keychain.sh
        ~/.local/bin/unlock-keychain.sh >/dev/null 2>&1
    end
```

- [ ] **Step 2: Verify fish parses the config**

Run: `fish -n home/dot_config/fish/config.fish`
Expected: no output, exit 0 (syntax OK). On Linux the `uname` guard makes the block a no-op at runtime.

- [ ] **Step 3: Commit**

```bash
git add home/dot_config/fish/config.fish
git commit -m "feat: auto-unlock macOS keychain on interactive fish startup"
```

---

## Task 3: Add macOS keychain stage to install.sh

**Files:**
- Modify: `install.sh` (add `stage_keychain` function after `stage_fish` which ends at line 243; update `main` and stage-label numbering)

- [ ] **Step 1: Add the `stage_keychain` function**

Insert after the `stage_fish` function (after its closing `}` on line 243):

```bash
stage_keychain() {
    if [[ "${SKIP_KEYCHAIN:-0}" == "1" ]]; then
        warn "Stage 5/5: keychain SKIPPED (SKIP_KEYCHAIN=1)"
        return
    fi
    if [[ "$OS" != "macos" ]]; then
        return
    fi
    info "Stage 5/5: macOS login keychain auto-unlock"

    # Idempotent zsh wiring — append grep-guarded block to ~/.zshrc.
    local zshrc="$HOME/.zshrc"
    if ! grep -q 'unlock-keychain.sh' "$zshrc" 2>/dev/null; then
        info "Wiring keychain auto-unlock into ~/.zshrc"
        cat >> "$zshrc" <<'ZRC'

# macOS login keychain — auto-unlock from ~/.config/keychain-pw
if [[ "$(uname)" == "Darwin" && -x ~/.local/bin/unlock-keychain.sh ]]; then
    ~/.local/bin/unlock-keychain.sh >/dev/null 2>&1
fi
ZRC
    fi

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
```

- [ ] **Step 2: Call the stage in `main`**

In `main`, after the `stage_fish` call (line 258), add:

```bash
    stage_keychain
```

So the sequence reads:
```bash
    stage_bootstrap
    stage_dotfiles
    stage_mise
    stage_fish
    stage_keychain
```

- [ ] **Step 3: Renumber existing stage labels to /5**

Update the four existing stage labels (the strings only; logic unchanged):
- `stage_bootstrap`: `Stage 1/4: bootstrap …` → `Stage 1/5: bootstrap …` (line 114)
- `stage_dotfiles`: both `Stage 2/4` strings (lines 150, 153) → `Stage 2/5`
- `stage_mise`: both `Stage 3/4` strings (lines 165, 168) → `Stage 3/5`
- `stage_fish`: both `Stage 4/4` strings (lines 213, 217) → `Stage 4/5`

- [ ] **Step 4: Lint install.sh**

Run: `shellcheck install.sh`
Expected: no errors (exit 0), matching the existing CI `shellcheck` job.

- [ ] **Step 5: Verify non-macOS no-op + idempotency on this Linux box**

Run:
```bash
SKIP_DOTFILES=1 SKIP_MISE=1 SKIP_FISH=1 NONINTERACTIVE=1 bash install.sh
```
Expected: completes; `stage_keychain` returns early (OS is `wsl`/`ubuntu`, not `macos`); no `~/.zshrc` modification on this machine; "Setup complete!" prints.

- [ ] **Step 6: Commit**

```bash
git add install.sh
git commit -m "feat: install.sh stage for macOS keychain password + zsh wiring"
```

---

## Task 4: Document the per-machine password step in README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Locate an insertion point**

Run: `grep -n '^##' README.md`
Expected: a list of section headings. Choose to add a new `## macOS login keychain` section near the usage/notes area (after the install/usage section).

- [ ] **Step 2: Add the documentation section**

Insert this section:

```markdown
## macOS login keychain (auto-unlock)

On macOS, interactive shells auto-unlock the login keychain using a password
read from `~/.config/keychain-pw`. `install.sh` prompts to save it once per
machine; if missing, the shell falls back to an interactive `security` prompt.

```bash
# Save it manually (one-time, per-machine):
mkdir -p ~/.config
umask 077; read -rsp "login keychain password: " PW; printf "%s" "$PW" > ~/.config/keychain-pw
chmod 600 ~/.config/keychain-pw

# Verify:
~/.local/bin/unlock-keychain.sh && echo "unlocked OK"
```

> `~/.config/keychain-pw` is **per-machine and never committed** (this repo is
> public). Re-save it if you change your macOS login password.
```

- [ ] **Step 3: Verify markdown renders sensibly**

Run: `grep -n 'keychain-pw' README.md`
Expected: matches inside the new section confirming the block landed.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "docs: document macOS keychain auto-unlock setup"
```

---

## Self-Review Notes

- **Spec coverage:** script (T1), fish wiring (T2), zsh wiring + install prompt (T3), secrets/docs (T4). All five spec components mapped.
- **Guards:** every runtime path checks `Darwin`/`macos`; CI stays green via `NONINTERACTIVE`/non-TTY skip and OS guard.
- **Idempotency:** zsh block grep-guarded on `unlock-keychain.sh`; password save skips if file exists.
- **Naming consistency:** path `~/.local/bin/unlock-keychain.sh`, file `~/.config/keychain-pw`, flag `SKIP_KEYCHAIN`, stage `stage_keychain` used identically across all tasks.
