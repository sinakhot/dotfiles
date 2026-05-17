function fish_greeting --description "sinakhot/dotfiles tool dashboard"
    set -l title (set_color -o cyan)
    set -l desc (set_color brblack)
    set -l reset (set_color normal)

    echo
    printf "  %ssinakhot/dotfiles%s %s— fish + zellij + mise stack%s\n" $title $reset $desc $reset
    echo

    __sinakhot_table "Shell & Prompt"   \
        fish      "interactive shell"   \
        starship  "prompt (k8s, git)"   \
        zellij    "mux + persistence"   \
        fisher    "fish plugin mgr"

    __sinakhot_table "Config Manager"   \
        chezmoi   "dotfile sync"        \
        mise      "tool version mgr"

    __sinakhot_table "Nav & Search"     \
        fzf       "fuzzy finder"        \
        zoxide    "smart cd (frecency)" \
        rg        "fast recursive grep" \
        fd        "fast find"

    __sinakhot_table "Read & Diff"      \
        bat       "cat + syntax color"  \
        eza       "ls modern (ll/lt)"   \
        delta     "git diff pager"      \
        tldr      "community man pages"

    __sinakhot_table "Git & Dev"        \
        gh        "GitHub CLI"          \
        lazygit   "TUI git client"      \
        direnv    "per-dir env vars"    \
        task      "Taskfile.yml runner" \
        xh        "modern HTTP client"  \
        hyperfine "CLI benchmark"

    __sinakhot_table "Languages"        \
        node      "Node.js LTS"         \
        python    "Python 3.12"         \
        go        "Go latest"           \
        uv        "Python pkg/proj"     \
        cargo-binstall "Rust prebuilts"

    __sinakhot_table "Editor"           \
        nvim      "Neovim (vim aliased)"

    __sinakhot_table "Kubernetes"       \
        kubectl   "k8s CLI"             \
        k9s       "k8s TUI"             \
        kubectx   "switch context"      \
        stern     "multi-pod log tail"  \
        helm      "Helm chart CLI"      \
        flux      "Flux GitOps CLI"

    __sinakhot_table "Secrets"          \
        sops      "edit encrypted yaml" \
        age       "file encryption"

    __sinakhot_table "System Monitor"   \
        btop      "process TUI"         \
        dust      "disk usage tree"     \
        duf       "filesystem usage"    \
        procs     "ps modern"

    __sinakhot_table "Data Wrangling"   \
        jq        "JSON query"          \
        yq        "YAML query"          \
        gron      "JSON greppable"      \
        mlr       "awk for CSV/JSON"

    # ── Workflow hero at END so it stays in view ─────────────────
    set -l hero (set_color -o magenta)
    set -l key (set_color -o yellow)
    echo
    printf "  %s▸ Zellij workflow%s %s(persistent sessions, auto-save 60s)%s\n" $hero $reset $desc $reset
    printf "      %sz%s             attach (or create) session \"default\"\n" $key $reset
    printf "      %sCtrl-g%s        unlock → %sp%s pane  %st%s tab  %sn%s new  %so%s session ops\n" \
        $key $reset $key $reset $key $reset $key $reset $key $reset
    printf "      %sCtrl-g o d%s    detach (session keeps running)\n" $key $reset
    printf "      %szls%s           list sessions      %szk%s NAME   kill\n" $key $reset $key $reset
    printf "      %s└─ saves layout + cwds + commands + scrollback%s\n" $desc $reset
    echo
end

function __sinakhot_table --description "render category as 2-column tool table"
    set -l section_color (set_color -o blue)
    set -l reset (set_color normal)

    printf "  %s▸ %s%s\n" $section_color $argv[1] $reset

    set -l pairs $argv[2..-1]
    set -l count (count $pairs)
    set -l i 1
    while test $i -le $count
        set -l name1 $pairs[$i]
        set -l desc1 $pairs[(math $i + 1)]
        set -l j (math $i + 2)
        if test $j -le $count
            set -l name2 $pairs[$j]
            set -l desc2 $pairs[(math $j + 1)]
            __sinakhot_cell $name1 $desc1
            printf "   "
            __sinakhot_cell $name2 $desc2
            echo
            set i (math $i + 4)
        else
            __sinakhot_cell $name1 $desc1
            echo
            set i (math $i + 2)
        end
    end
end

function __sinakhot_cell --description "render one name+desc cell"
    set -l name $argv[1]
    set -l description $argv[2]
    set -l ok (set_color -o green)
    set -l miss (set_color -o red)
    set -l desc_color (set_color brblack)
    set -l reset (set_color normal)

    if command -q $name; or functions -q $name
        printf "    %s%-14s%s %s%-20s%s" $ok $name $reset $desc_color $description $reset
    else
        printf "    %s%-14s%s %s%-20s%s" $miss $name $reset $desc_color $description $reset
    end
end
