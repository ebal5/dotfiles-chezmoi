#!/usr/bin/env bash
# Claude Codeフック用tmuxウィンドウタイトル管理スクリプト
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <session-start|worktree-create|worktree-remove|session-end>" >&2
  exit 1
fi

action="$1"

# stdinを読み捨てる（フックはJSON入力を渡すため）
input=$(cat)

# tmux外では何もしない
if [[ -z "${TMUX:-}" ]]; then
  exit 0
fi

window_id=$(tmux display-message -p '#I')
save_file="/tmp/tmux_claude_title_${window_id}"

case "$action" in
  "session-start")
    # 現在のウィンドウ名を保存してクロードタイトルに変更
    tmux display-message -p '#W' >"$save_file"
    tmux rename-window "🤖 claude" 2>/dev/null || true
    ;;
  "worktree-create")
    # worktree名を取得してタイトルに設定（stdoutはworktreeパス用に予約）
    {
      name=$(echo "$input" | jq -r '.name // empty' 2>/dev/null) || name=""
      if [[ -n "$name" ]]; then
        tmux rename-window "🤖 ${name}" 2>/dev/null || true
      fi
    } >/dev/null
    ;;
  "worktree-remove")
    tmux rename-window "🤖 claude" 2>/dev/null || true
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
