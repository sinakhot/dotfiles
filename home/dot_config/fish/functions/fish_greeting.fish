function fish_greeting --description "sinakhot/dotfiles tool dashboard"
    set -l title (set_color -o cyan)
    set -l desc (set_color brblack)
    set -l reset (set_color normal)

    echo
    printf "  %ssinakhot/dotfiles%s %s— fish + zellij + mise stack    %s(type %scheat%s%s to redisplay)%s\n" \
        $title $reset $desc $desc (set_color -o yellow) $reset $desc $reset
    echo

    __sinakhot_table "Shell & Prompt"   \
        fish      "interactive"         \
        starship  "prompt+k8s"          \
        zellij    "multiplexer"         \
        fisher    "plugin mgr"

    __sinakhot_table "Config Manager"   \
        chezmoi   "dotfile sync"        \
        mise      "version mgr"

    __sinakhot_table "Nav & Search"     \
        fzf       "fuzzy finder"        \
        zoxide    "smart cd"            \
        rg        "fast grep"           \
        fd        "fast find"

    __sinakhot_table "Read & Diff"      \
        bat       "cat + colors"        \
        eza       "ls modern"           \
        delta     "diff pager"          \
        tldr      "cheatsheets"

    __sinakhot_table "Git & Dev"        \
        gh        "GitHub CLI"          \
        lazygit   "git TUI"             \
        direnv    "per-dir env"         \
        task      "task runner"         \
        xh        "HTTP client"         \
        hyperfine "benchmark"

    __sinakhot_table "Languages"        \
        node      "Node.js LTS"         \
        python    "Python 3.12"         \
        go        "Go latest"           \
        uv        "Py pkg+venv"         \
        cargo-binstall "Rust crates"

    __sinakhot_table "Editor"           \
        nvim      "Neovim"

    __sinakhot_table "Kubernetes"       \
        kubectl   "k8s CLI"             \
        k9s       "k8s TUI"             \
        kubectx   "ctx switch"          \
        stern     "multi-pod log"       \
        helm      "Helm CLI"            \
        flux      "Flux CLI"

    __sinakhot_table "Secrets"          \
        sops      "encrypt yaml"        \
        age       "encryption"          \
        keychain  "ssh-agent mgr"

    __sinakhot_table "System Monitor"   \
        btop      "process TUI"         \
        dust      "disk usage"          \
        duf       "fs usage"            \
        procs     "ps modern"

    __sinakhot_table "Data Wrangling"   \
        jq        "JSON query"          \
        yq        "YAML query"          \
        gron      "JSON flatten"        \
        mlr       "CSV awk"

    # ── Workflow hero at END so it stays in view ─────────────────
    set -l hero (set_color -o magenta)
    set -l key (set_color -o yellow)
    echo
    printf "  %s▸ Zellij workflow%s %s(persistent sessions, auto-save 60s)%s\n" $hero $reset $desc $reset
    printf "      %sz%s             attach (or create) session \"default\"\n" $key $reset
    printf "      %sCtrl-g%s        unlock → %sp%s pane  %st%s tab  %sn%s new  %so%s session ops\n" \
        $key $reset $key $reset $key $reset $key $reset $key $reset
    printf "      %sCtrl-q%s        detach (session keeps running)\n" $key $reset
    printf "      %szls%s  list   %szk%s kill   %szd%s delete   %szda%s wipe all\n" \
        $key $reset $key $reset $key $reset $key $reset
    printf "      %s└─ saves layout + cwds + commands + scrollback%s\n" $desc $reset
    echo
    printf "  %s▸ SSH keychain%s %s(one agent per boot, shared across shells)%s\n" $hero $reset $desc $reset
    printf "      %sssh-add%s        load default keys (~/.ssh/id_*) into agent\n" $key $reset
    printf "      %sssh-add ~/.ssh/KEY%s   load specific key\n" $key $reset
    printf "      %sssh-add -l%s     list loaded keys   %sssh-add -D%s  drop all\n" $key $reset $key $reset
    printf "      %s└─ keys persist until reboot; devcontainers inherit via \$SSH_AUTH_SOCK%s\n" $desc $reset
    echo
    printf "  %s▸ Yazi file manager%s %s(blazing TUI, cd-on-quit)%s\n" $hero $reset $desc $reset
    printf "      %sy%s             fullscreen yazi; on quit, shell cd's to last dir\n" $key $reset
    printf "      %sAlt-y%s         floating yazi pane inside zellij (close on exit)\n" $key $reset
    printf "      %sEnter%s open   %sSpace%s select   %sa%s create   %sd%s trash   %sr%s rename\n" \
        $key $reset $key $reset $key $reset $key $reset $key $reset
    printf "      %s/%s find   %sgg%s/%sG%s top/bottom   %sTab%s preview   %sq%s quit\n" \
        $key $reset $key $reset $key $reset $key $reset $key $reset
    printf "      %s└─ %sy%s wrapper writes cwd to tmpfile so shell cd's there on quit%s\n" $desc $key $desc $reset
    echo
    printf "  %s▸ DevPod%s %s(devcontainers anywhere — docker/k8s/cloud backends)%s\n" $hero $reset $desc $reset
    printf "      %sdevpod provider add docker%s   one-time: register a backend\n" $key $reset
    printf "      %sdevpod up .%s          start/attach a workspace from this repo\n" $key $reset
    printf "      %sdevpod up REPO_URL%s   spin one up straight from a git URL\n" $key $reset
    printf "      %sdevpod ssh NAME%s      ssh in   %sdevpod list%s  list   %sdevpod status NAME%s  state\n" \
        $key $reset $key $reset $key $reset
    printf "      %sdevpod stop NAME%s     stop (keep)   %sdevpod delete NAME%s  remove\n" $key $reset $key $reset
    printf "      %s└─ reads .devcontainer/; keychain creds work via ~/.ssh/rc unlock%s\n" $desc $reset
    echo
end

function __sinakhot_table --description "render category as 4-column tool table"
    set -l section_color (set_color -o blue)
    set -l reset (set_color normal)

    printf "  %s▸ %s%s\n" $section_color $argv[1] $reset

    set -l pairs $argv[2..-1]
    set -l count (count $pairs)
    set -l i 1
    while test $i -le $count
        printf "    "
        for col in 1 2 3 4
            if test $i -le $count
                set -l n $pairs[$i]
                set -l d $pairs[(math $i + 1)]
                __sinakhot_cell $n $d
                set i (math $i + 2)
                if test $col -lt 4
                    printf "  "
                end
            end
        end
        echo
    end
end

function __sinakhot_cell --description "render one name+desc cell (no leading indent)"
    set -l name $argv[1]
    set -l description $argv[2]
    set -l ok (set_color -o green)
    set -l miss (set_color -o red)
    set -l desc_color (set_color brblack)
    set -l reset (set_color normal)

    if command -q $name; or functions -q $name
        printf "%s%-14s%s %s%-13s%s" $ok $name $reset $desc_color $description $reset
    else
        printf "%s%-14s%s %s%-13s%s" $miss $name $reset $desc_color $description $reset
    end
end
