function fish_greeting --description "sinakhot/dotfiles tool dashboard"
    set -l title (set_color -o cyan)
    set -l dim (set_color brblack)
    set -l label (set_color -o blue)
    set -l ok (set_color green)
    set -l miss (set_color -o red)
    set -l reset (set_color normal)

    echo
    printf "  %ssinakhot/dotfiles%s %s— tools available%s\n" $title $reset $dim $reset
    echo

    __sinakhot_row "Shell + Prompt" fish starship zellij fisher
    __sinakhot_row "Config Manager" chezmoi mise
    __sinakhot_row "Nav + Search  " fzf zoxide rg fd
    __sinakhot_row "Read + Diff   " bat eza delta
    __sinakhot_row "Git + Dev     " gh lazygit direnv task
    __sinakhot_row "Languages     " node python go uv cargo-binstall
    __sinakhot_row "Editor        " nvim
    __sinakhot_row "System Monitor" btop dust duf procs
    __sinakhot_row "Data Wrangling" jq yq gron mlr

    echo
    printf "  %sabbrs%s  %sz%s=zellij  %sll%s=eza -lah  %slg%s=lazygit  %scm%s=chezmoi  %skgp%s=k get pods\n" \
        $dim $reset \
        $ok $reset $ok $reset $ok $reset $ok $reset $ok $reset
    echo
end

function __sinakhot_row --description "render one tool category row"
    set -l label_text $argv[1]
    set -l tools $argv[2..-1]
    set -l clabel (set_color -o blue)
    set -l cok (set_color green)
    set -l cmiss (set_color -o red)
    set -l creset (set_color normal)

    printf "  %s%s%s  " $clabel $label_text $creset
    for t in $tools
        if command -q $t; or functions -q $t
            printf "%s%s%s " $cok $t $creset
        else
            printf "%s%s%s " $cmiss $t $creset
        end
    end
    echo
end
