#!/bin/bash
set -euo pipefail
KC="${1:-$HOME/Library/Keychains/login.keychain-db}"
PW_FILE="$HOME/.config/keychain-pw"

if [[ ! -f "$PW_FILE" ]]; then
  echo "no password file at $PW_FILE — falling back to interactive prompt" >&2
  exec security unlock-keychain "$KC"
fi

# -p reads password from arg. Brief argv exposure to same user only, who can
# already read PW_FILE. `security -i` does NOT take a piped password (it is an
# interactive command shell), so that approach silently fell through to a prompt.
security unlock-keychain -p "$(cat "$PW_FILE")" "$KC"
