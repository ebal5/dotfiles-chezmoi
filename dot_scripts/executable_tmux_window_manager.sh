#!/bin/bash

# =============================================================================
# TMUX ウィンドウ名管理スクリプト
# =============================================================================
#
# 使用方法:
#   ./tmux_window_manager.sh auto          # 自動命名
#   ./tmux_window_manager.sh git           # Gitブランチ付き命名
#   ./tmux_window_manager.sh project       # プロジェクト名のみ
#   ./tmux_window_manager.sh time          # 時間ベース命名
#   ./tmux_window_manager.sh custom "名前"  # カスタム命名
#   ./tmux_window_manager.sh smart         # スマート命名（推奨）
#
# =============================================================================

set -euo pipefail

# 色付き出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# プロジェクトタイプの検出
detect_project_type() {
  local dir="$1"

  # 各プロジェクトタイプの検出
  if [[ -f "$dir/package.json" ]]; then
    echo "📦"
  elif [[ -f "$dir/Cargo.toml" ]]; then
    echo "🦀"
  elif [[ -f "$dir/pyproject.toml" ]] || [[ -f "$dir/requirements.txt" ]]; then
    echo "🐍"
  elif [[ -f "$dir/docker-compose.yml" ]] || [[ -f "$dir/Dockerfile" ]]; then
    echo "🐳"
  elif [[ -f "$dir/go.mod" ]]; then
    echo "🐹"
  elif [[ -f "$dir/Gemfile" ]]; then
    echo "💎"
  elif [[ -f "$dir/pom.xml" ]]; then
    echo "☕"
  elif [[ -f "$dir/Makefile" ]]; then
    echo "🔨"
  elif [[ -f "$dir/README.md" ]]; then
    echo "📖"
  else
    echo "📁"
  fi
}

# Git情報の取得
get_git_info() {
  local dir="$1"

  if [[ -d "$dir/.git" ]]; then
    local branch
    branch=$(git -C "$dir" branch --show-current 2>/dev/null || echo "main")
    local status
    if git -C "$dir" diff --quiet 2>/dev/null; then
      status=""
    else
      status="*"
    fi
    echo ":$branch$status"
  else
    echo ""
  fi
}

# プロジェクト名の取得
get_project_name() {
  local dir="$1"

  # Gitリポジトリの場合
  if [[ -d "$dir/.git" ]]; then
    local repo_name
    repo_name=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null | xargs basename 2>/dev/null || echo "")
    if [[ -n "$repo_name" ]]; then
      echo "$repo_name"
      return
    fi
  fi

  # ディレクトリ名を使用
  basename "$dir"
}

# スマート命名（推奨）
smart_rename() {
  local current_dir
  current_dir=$(pwd)

  local project_name
  project_name=$(get_project_name "$current_dir")

  local project_type
  project_type=$(detect_project_type "$current_dir")

  local git_info
  git_info=$(get_git_info "$current_dir")

  local window_name="$project_type $project_name$git_info"

  if tmux rename-window "$window_name" 2>/dev/null; then
    log_info "ウィンドウ名を '$window_name' に変更しました"
  else
    log_error "ウィンドウ名の変更に失敗しました"
    return 1
  fi
}

# 自動命名
auto_rename() {
  local current_dir
  current_dir=$(pwd)

  local project_name
  project_name=$(get_project_name "$current_dir")

  if tmux rename-window "$project_name" 2>/dev/null; then
    log_info "ウィンドウ名を '$project_name' に変更しました"
  else
    log_error "ウィンドウ名の変更に失敗しました"
    return 1
  fi
}

# Gitブランチ付き命名
git_rename() {
  local current_dir
  current_dir=$(pwd)

  local project_name
  project_name=$(get_project_name "$current_dir")

  local git_info
  git_info=$(get_git_info "$current_dir")

  if [[ -z "$git_info" ]]; then
    log_warn "Gitリポジトリではありません"
    auto_rename
    return
  fi

  local window_name="$project_name$git_info"

  if tmux rename-window "$window_name" 2>/dev/null; then
    log_info "ウィンドウ名を '$window_name' に変更しました"
  else
    log_error "ウィンドウ名の変更に失敗しました"
    return 1
  fi
}

# プロジェクト名のみ
project_rename() {
  local current_dir
  current_dir=$(pwd)

  local project_name
  project_name=$(get_project_name "$current_dir")

  if tmux rename-window "$project_name" 2>/dev/null; then
    log_info "ウィンドウ名を '$project_name' に変更しました"
  else
    log_error "ウィンドウ名の変更に失敗しました"
    return 1
  fi
}

# 時間ベース命名
time_rename() {
  local time_str
  time_str=$(date +"%H:%M")

  if tmux rename-window "$time_str" 2>/dev/null; then
    log_info "ウィンドウ名を '$time_str' に変更しました"
  else
    log_error "ウィンドウ名の変更に失敗しました"
    return 1
  fi
}

# カスタム命名
custom_rename() {
  local custom_name="$1"

  if [[ -z "$custom_name" ]]; then
    log_error "カスタム名が指定されていません"
    return 1
  fi

  if tmux rename-window "$custom_name" 2>/dev/null; then
    log_info "ウィンドウ名を '$custom_name' に変更しました"
  else
    log_error "ウィンドウ名の変更に失敗しました"
    return 1
  fi
}

# 現在のウィンドウ名を表示
show_current_name() {
  local current_name
  current_name=$(tmux display-message -p '#W' 2>/dev/null || echo "取得できません")
  log_info "現在のウィンドウ名: $current_name"
}

# ヘルプ表示
show_help() {
  cat <<EOF
${BLUE}TMUX ウィンドウ名管理スクリプト${NC}

${GREEN}使用方法:${NC}
  $0 auto                    # 自動命名（プロジェクト名のみ）
  $0 git                     # Gitブランチ付き命名
  $0 project                 # プロジェクト名のみ
  $0 time                    # 時間ベース命名
  $0 custom "名前"            # カスタム命名
  $0 smart                   # スマート命名（推奨）
  $0 show                    # 現在のウィンドウ名を表示
  $0 help                    # このヘルプを表示

${GREEN}例:${NC}
  $0 smart                   # 🐍 myproject:main
  $0 git                     # myproject:main
  $0 custom "開発サーバー"     # 開発サーバー
  $0 time                    # 14:30

${GREEN}キーバインド例:${NC}
  bind-key M-s run-shell '$0 smart'
  bind-key M-g run-shell '$0 git'
  bind-key M-t run-shell '$0 time'
EOF
}

# メイン処理
main() {
  local command="${1:-help}"

  case "$command" in
    "auto")
      auto_rename
      ;;
    "git")
      git_rename
      ;;
    "project")
      project_rename
      ;;
    "time")
      time_rename
      ;;
    "custom")
      custom_rename "${2:-}"
      ;;
    "smart")
      smart_rename
      ;;
    "show")
      show_current_name
      ;;
    "help" | "-h" | "--help")
      show_help
      ;;
    *)
      log_error "不明なコマンド: $command"
      show_help
      exit 1
      ;;
  esac
}

# スクリプト実行
main "$@"
