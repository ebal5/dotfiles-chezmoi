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
    # ブランチ名を取得してタイトルに含める
    branch=$(git --no-optional-locks branch 2>/dev/null | grep '\*' | colrm 1 2) || branch=""
    if [[ -n "$branch" ]]; then
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
