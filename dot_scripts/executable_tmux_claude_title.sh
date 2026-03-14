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

window_id=$(tmux display-message -p '#I')
save_file="/tmp/tmux_claude_title_${window_id}"

case "$action" in
  "session-start")
    # 現在のウィンドウ名を保存
    tmux display-message -p '#W' >"$save_file"
    # ブランチ名を取得してタイトルに含める
    branch=$(git --no-optional-locks branch 2>/dev/null | grep '\*' | colrm 1 2) || branch=""
    if [[ -n "$branch" ]]; then
      tmux rename-window "🤖 ${branch}" 2>/dev/null || true
    else
      tmux rename-window "🤖 claude" 2>/dev/null || true
    fi
    ;;
  "session-end")
    # 保存した元のウィンドウ名を復元
    if [[ -f "$save_file" ]]; then
      saved_name=$(cat "$save_file")
      tmux rename-window "$saved_name" 2>/dev/null || true
      rm -f "$save_file"
    else
      tmux rename-window "$(basename "$(pwd)")" 2>/dev/null || true
    fi
    ;;
  *)
    echo "Unknown action: $action" >&2
    exit 1
    ;;
esac
