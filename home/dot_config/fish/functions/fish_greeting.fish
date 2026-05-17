function fish_greeting --description "sinakhot/dotfiles tool dashboard"
    set -l title (set_color -o cyan)
    set -l section (set_color -o blue)
    set -l name_ok (set_color -o green)
    set -l name_miss (set_color -o red)
    set -l desc (set_color brblack)
    set -l reset (set_color normal)

    echo
    printf "  %ssinakhot/dotfiles%s %s— fish + zellij + mise stack%s\n" $title $reset $desc $reset
    echo

    # ── Hero: zellij = main entry point ──────────────────────────
    set -l hero (set_color -o magenta)
    set -l key (set_color -o yellow)
    printf "  %s▸ Workflow%s\n" $hero $reset
    printf "      %sz%s              attach (or create) persistent session \"default\"\n" $key $reset
    printf "      %sCtrl-g%s         unlock → single key:  %sp%s pane  %st%s tab  %sn%s new  %so%s session ops\n" \
        $key $reset $key $reset $key $reset $key $reset $key $reset
    printf "      %sCtrl-g o d%s     detach (session keeps running in background)\n" $key $reset
    printf "      %szls%s            list sessions     %szk%s NAME   kill named session\n" $key $reset $key $reset
    printf "      %s└─ auto-save every 60s: layout + cwds + commands + scrollback%s\n" $desc $reset
    echo

    __sinakhot_section "Shell & Prompt"
    __sinakhot_tool fish       "interactive shell"
    __sinakhot_tool starship   "prompt (k8s ctx, git, langs)"
    __sinakhot_tool zellij     "multiplexer + session persistence (z=attach)"
    __sinakhot_tool fisher     "fish plugin manager"

    __sinakhot_section "Config Manager"
    __sinakhot_tool chezmoi    "dotfile sync (cm=chezmoi, cma=apply, cme=edit)"
    __sinakhot_tool mise       "tool version manager (node/python/go + ubi)"

    __sinakhot_section "Nav & Search"
    __sinakhot_tool fzf        "fuzzy finder (Ctrl-T file, Ctrl-R hist, Alt-C cd)"
    __sinakhot_tool zoxide     "smart cd by frecency (cd foo jumps to learned path)"
    __sinakhot_tool rg         "ripgrep — fast recursive grep"
    __sinakhot_tool fd         "fast find alternative (fd pattern)"

    __sinakhot_section "Read & Diff"
    __sinakhot_tool bat        "cat w/ syntax highlight (alias of cat)"
    __sinakhot_tool eza        "ls modern (ll=detailed, lt=tree)"
    __sinakhot_tool delta      "git diff pager (side-by-side, syntax)"
    __sinakhot_tool tldr       "community man pages (tldr tar)"

    __sinakhot_section "Git & Dev"
    __sinakhot_tool gh         "GitHub CLI (PRs, issues, runs)"
    __sinakhot_tool lazygit    "TUI git client (lg)"
    __sinakhot_tool direnv     "per-directory env vars (.envrc)"
    __sinakhot_tool task       "go-task — Taskfile.yml runner"
    __sinakhot_tool xh         "modern HTTP client (curl/httpie alt)"
    __sinakhot_tool hyperfine  "CLI benchmark w/ stats"

    __sinakhot_section "Languages"
    __sinakhot_tool node       "Node.js LTS (via mise)"
    __sinakhot_tool python     "Python 3.12 (via mise)"
    __sinakhot_tool go         "Go latest (via mise)"
    __sinakhot_tool uv         "Python pkg/proj manager (pip+venv+pipx fused)"
    __sinakhot_tool cargo-binstall "install prebuilt Rust crates fast"

    __sinakhot_section "Editor"
    __sinakhot_tool nvim       "Neovim — vim/vi aliased; \$EDITOR"

    __sinakhot_section "Kubernetes"
    __sinakhot_tool kubectl    "k8s CLI (k=kubectl, kgp=get pods, kgs=get svc)"
    __sinakhot_tool k9s        "k8s TUI — browse pods/logs/exec interactively"
    __sinakhot_tool kubectx    "switch kubeconfig context fast"
    __sinakhot_tool stern      "multi-pod log tail (stern -n auth authentik)"
    __sinakhot_tool helm       "Helm chart CLI"
    __sinakhot_tool flux       "Flux GitOps CLI (reconcile, get hr, suspend/resume)"

    __sinakhot_section "Secrets"
    __sinakhot_tool sops       "edit encrypted YAML/JSON secrets in place"
    __sinakhot_tool age        "small modern file encryption (sops backend)"

    __sinakhot_section "System Monitor"
    __sinakhot_tool btop       "process/CPU/mem TUI"
    __sinakhot_tool dust       "du modern — disk usage tree"
    __sinakhot_tool duf        "df modern — filesystem usage"
    __sinakhot_tool procs      "ps modern — colored process list"

    __sinakhot_section "Data Wrangling"
    __sinakhot_tool jq         "JSON query/transform"
    __sinakhot_tool yq         "YAML/XML/TOML query (jq-compat)"
    __sinakhot_tool gron       "flatten JSON to greppable lines"
    __sinakhot_tool mlr        "miller — awk for CSV/TSV/JSON"

    echo
    printf "  %sabbrs%s  z lg ll lt cm cma cme g gs gd gl k kgp kgs vim→nvim\n" $desc $reset
    echo
end

function __sinakhot_section --description "category header"
    set -l section (set_color -o blue)
    set -l reset (set_color normal)
    printf "  %s▸ %s%s\n" $section $argv[1] $reset
end

function __sinakhot_tool --description "render one tool + description line"
    set -l tool $argv[1]
    set -l description $argv[2]
    set -l name_ok (set_color -o green)
    set -l name_miss (set_color -o red)
    set -l desc_color (set_color brblack)
    set -l reset (set_color normal)

    if command -q $tool; or functions -q $tool
        printf "      %s%-16s%s %s%s%s\n" $name_ok $tool $reset $desc_color $description $reset
    else
        printf "      %s%-16s%s %s%s (missing)%s\n" $name_miss $tool $reset $desc_color $description $reset
    end
end
