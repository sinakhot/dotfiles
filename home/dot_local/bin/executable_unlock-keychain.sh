#!/bin/bash
set -euo pipefail
KC="${1:-$HOME/Library/Keychains/login.keychain-db}"
PW_FILE="$HOME/.config/keychain-pw"

if [[ ! -f "$PW_FILE" ]]; then
  echo "no password file at $PW_FILE — falling back to interactive prompt" >&2
  exec security -i unlock-keychain "$KC"
fi

# Pipe password via stdin (interactive mode) so it never lands in argv / ps output.
printf '%s' "$(< "$PW_FILE")" | security -i unlock-keychain "$KC"
