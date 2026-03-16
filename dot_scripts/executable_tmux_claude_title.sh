#!/usr/bin/env bash
# Claude Codeフック用tmuxウィンドウタイトル管理スクリプト
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <session-start|session-end>" >&2
  exit 1
fi

action="$1"

# stdinを読み捨てる（フックはJSON入力を渡すため）
cat >/dev/null

# tmux外では何もしない
if [[ -z "${TMUX:-}" ]]; then
  exit 0
fi

case "$action" in
  "session-start")
    # automatic-renameを無効化してタイトルを固定
    tmux set-option -w automatic-rename off 2>/dev/null || true

    # リポジトリ名を取得
    repo_dir=""
    repo_name=""
    if repo_dir=$(git --no-optional-locks rev-parse --show-toplevel 2>/dev/null); then
      repo_name=$(basename "$repo_dir")

      # 設定ファイルから短縮名を参照
      config_file="$HOME/.config/local/tmux_repo_names"
      if [[ -f "$config_file" ]]; then
        while IFS='=' read -r key value; do
          # 前後の空白をトリム
          key="${key#"${key%%[![:space:]]*}"}"
          key="${key%"${key##*[![:space:]]}"}"
          value="${value#"${value%%[![:space:]]*}"}"
          value="${value%"${value##*[![:space:]]}"}"
          # コメントと空行をスキップ
          [[ -z "$key" || "$key" == \#* ]] && continue
          if [[ "$key" == "$repo_name" ]]; then
            repo_name="$value"
            break
          fi
        done <"$config_file"
      fi
    fi

    # ブランチ名を取得
    branch=""
    if ! branch=$(git --no-optional-locks branch --show-current 2>/dev/null) || [[ -z "$branch" ]]; then
      # detached HEAD時はコミットハッシュを表示
      branch=$(git --no-optional-locks rev-parse --short HEAD 2>/dev/null) || branch=""
    fi

    # タイトルを設定
    if [[ -n "$repo_name" && -n "$branch" ]]; then
      tmux rename-window "🤖 ${repo_name}:${branch}" 2>/dev/null || true
    elif [[ -n "$branch" ]]; then
      tmux rename-window "🤖 ${branch}" 2>/dev/null || true
    else
      tmux rename-window "🤖 claude" 2>/dev/null || true
    fi
    ;;
  "session-end")
    # automatic-renameを再有効化してシェル名を自動表示
    tmux set-option -w automatic-rename on 2>/dev/null || true
    ;;
  *)
    echo "Unknown action: $action" >&2
    exit 1
    ;;
esac
