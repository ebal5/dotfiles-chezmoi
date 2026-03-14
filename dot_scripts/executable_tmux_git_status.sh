#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# tmux ステータスバー用 Git 情報表示
# =============================================================================
#
# 使用方法:
#   tmux_git_status.sh [directory]
#
# 出力例:
#   " main ✓ "       - リモートと同期済み
#   " main ↑2 "      - 2コミット先行
#   " main ↓3 "      - 3コミット遅延
#   " main ↑1↓2 "    - 先行・遅延あり
#   " feature "       - upstream未設定
#   (空)              - Gitリポジトリ外
#
# =============================================================================

dir="${1:-.}"

# Gitリポジトリかチェック
if ! git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

# ブランチ名を取得
branch=$(git -C "$dir" branch --show-current 2>/dev/null || true)
if [[ -z "$branch" ]]; then
  # detached HEAD の場合、短縮ハッシュを使用
  branch=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null || echo "???")
fi

# リモートとの同期状態を取得
sync=""
if ahead_behind=$(git -C "$dir" rev-list --left-right --count "HEAD...@{upstream}" 2>/dev/null); then
  ahead=$(echo "$ahead_behind" | cut -f1)
  behind=$(echo "$ahead_behind" | cut -f2)
  [[ "$ahead" -gt 0 ]] && sync+="↑${ahead}"
  [[ "$behind" -gt 0 ]] && sync+="↓${behind}"
  [[ -z "$sync" ]] && sync="✓"
fi

if [[ -n "$sync" ]]; then
  echo " ${branch} ${sync} "
else
  echo " ${branch} "
fi
