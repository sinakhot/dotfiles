function fish_greeting --description "sinakhot/dotfiles greeting (one-liner; run `cheat` for the full dashboard)"
    set -l desc (set_color brblack)
    set -l reset (set_color normal)
    printf "  %ssinakhot/dotfiles%s %s— fish + herdr + mise · type %scheat%s%s for the tool dashboard%s\n" \
        (set_color -o cyan) $reset $desc (set_color -o yellow) $reset $desc $reset
end
