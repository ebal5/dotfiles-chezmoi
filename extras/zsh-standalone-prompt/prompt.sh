# ==============================================================================
# お仕事Mac用：zsh標準機能プロンプト（Starshipカラー＋Viモード完全版）
# ==============================================================================

autoload -Uz vcs_info
setopt prompt_subst

# Viモードを有効化
bindkey -v
# Escを押したときの反応速度を爆速にする（ミリ秒指定）
export KEYTIMEOUT=1

# 1. 時刻 (淡いグレー)
function get_time() {
    echo "%F{242}⌚[ %* ]%f "
}

# 2. カレントディレクトリ (鮮やかなシアン。homeは🏠)
function get_dir() {
    # %2~ を評価してパスを取得し、~ を 🏠 に置換したあと、全体をシアン(%F{cyan})にする
    echo "%F{cyan}${$(print -P "%2~")//\~/🏠}%f"
}

# 3. Git (マゼンタ。アイコンとブランチ名を強調)
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' formats '%b' '%u%c'
zstyle ':vcs_info:git:*' actionformats '%b|%a' '%u%c'
# 変更がある場合は赤文字で「!」や「+」を表示
zstyle ':vcs_info:*' unstagedstr '%F{red}!%f'
zstyle ':vcs_info:*' stagedstr '%F{green}+%f'

function get_git_info() {
    if [[ -n "$vcs_info_msg_0_" ]]; then
        local branch="$vcs_info_msg_0_"
        local git_status="$vcs_info_msg_1_"

        if [[ "$branch" != "main" && "$branch" != "master" ]]; then
            if [[ -n "$git_status" ]]; then
                # 変更がある時はステータスも表示
                echo "%F{magenta}[ $branch ($git_status)]%f "
            else
                echo "%F{magenta}[ $branch]%f "
            fi
        fi
    fi
}

# 4. クライアント環境（AWSはオレンジ/ゴールド、Terraformは紫）
function get_env_info() {
    local env_str=""
    # AWS Profile (208番: オレンジ)
    if [[ -n "$AWS_PROFILE" ]]; then
        env_str+="%F{208}[󱇪 $AWS_PROFILE]%f "
    fi
    # Terraform Workspace (105番: 綺麗なパープル)
    if [[ -d .terraform && -f .terraform/environment ]]; then
        local tf_ws=$(cat .terraform/environment 2>/dev/null)
        if [[ -n "$tf_ws" ]]; then
            env_str+="%F{105}[󱁢 $tf_ws]%f "
        fi
    fi
    echo "${env_str}%f"
}

# 5. コマンド実行時間 (5秒以上で黄色)
function preexec() {
    timer=${timer:-$SECONDS}
}

# ==============================================================================
# 6. Viモード＆終了ステータス完全分離（Nerd Font対応）
# ==============================================================================
# デフォルトのモードアイコン（緑のペン 󰏫 ）
VIM_MODE_ICON="%F{green}󰏫%f"

function zle-line-init zle-line-finish zle-keymap-select {
    case $KEYMAP in
        vicmd)
            # ノーマルモード時：赤のVimロゴ
            VIM_MODE_ICON="%F{red}%f"
            ;;
        *)
            # インサートモード時：緑のペンアイコン 󰏫
            VIM_MODE_ICON="%F{green}󰏫%f"
            ;;
    esac
    zle reset-prompt
}
zle -N zle-line-init
zle -N zle-line-finish
zle -N zle-keymap-select

# 直前のコマンドの成否で ❯ の色を変える関数
function get_return_status() {
    # %(?.正常時の色.エラー時の色)
    echo "%(?.%F{green}❯%f.%F{red}❯%f)"
}

# precmdでは元のGit情報取得とタイマー処理を継続
function precmd() {
    vcs_info
    if [ "$timer" ]; then
        local duration=$(($SECONDS - $timer))
        if [ $duration -ge 5 ]; then
            PROMPT_DURATION="%F{yellow}⌛ ${duration}s%f "
        else
            PROMPT_DURATION=""
        fi
        unset timer
    fi
}

# ==============================================================================
# プロンプトの組み立て
# ==============================================================================
# ${VIM_MODE_ICON}（モードで切替）と $(get_return_status)（エラーで切替）を分離
PROMPT='
$(get_time)$(get_dir) $(get_git_info)$(get_env_info)${PROMPT_DURATION}
${VIM_MODE_ICON} $(get_return_status) '

# 複数行入力時のプロンプト
PS2='%F{green}▶▶ %f'
