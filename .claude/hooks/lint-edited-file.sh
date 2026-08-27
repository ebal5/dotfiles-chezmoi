#!/usr/bin/env bash
# Claude Code PostToolUse hook: 編集されたファイルをファイル種別ごとにlintする。
# 入力: stdin にフックイベントのJSON。出力: 問題があれば stderr + exit 2 でモデルへ返す。
set -uo pipefail

# lint結果をモデルに返す場合のみ exit 2。それ以外は必ず exit 0 で終える。
FEEDBACK_EXIT=2

log_and_exit() {
  # $1: モデルに返すメッセージ
  printf '%s\n' "$1" >&2
  exit "$FEEDBACK_EXIT"
}

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[[ -n "$file_path" && -f "$file_path" ]] || exit 0

# シンボリックリンクや `..` を解決してからプロジェクト境界を判定する。
# 文字列の前方一致だけだと `<project>/../outside/x.sh` が境界を通過し、
# プロジェクト外のファイルを shfmt が書き換えてしまう。
project_dir=$(realpath -- "${CLAUDE_PROJECT_DIR:-$PWD}" 2>/dev/null) || exit 0
file_path=$(realpath -- "$file_path" 2>/dev/null) || exit 0
[[ -f $file_path ]] || exit 0

# プロジェクト外のファイルはこのリポジトリのlint規約の対象外
case "$file_path" in
  "$project_dir"/*) ;;
  *) exit 0 ;;
esac

# リポジトリ固有の規約チェック（chezmoiテンプレート・shim定義）。
# CI/pre-commitと同じスクリプトを編集時点でも走らせる。
check_repo_conventions() {
  local checker="$project_dir/.github/scripts/check-repo-conventions.sh" out
  [[ -x $checker ]] || return 0
  out=$("$checker" "$file_path" 2>&1) && return 0
  log_and_exit "リポジトリ規約違反です（$file_path）。修正してください:

$out"
}

check_repo_conventions

# chezmoiテンプレートは Goテンプレート構文のため shfmt/shellcheck がパースできない。
# `.tmpl` に残っているのは分岐だけのランチャーで、シェルコードは `scripts/` 配下の
# 素の `.sh` にあり、そちらは下の通常経路で検査される
case "$file_path" in
  *.tmpl) exit 0 ;;
  *) ;;
esac

is_shell() {
  case "$file_path" in
    *.sh | *.bash) return 0 ;;
    *) ;;
  esac
  local first_line
  first_line=$(head -n 1 "$file_path")
  [[ $first_line == '#!'* ]] && grep -qE '\b(ba|da|k|z)?sh\b' <<<"$first_line"
}

lint_shell() {
  local out
  # フォーマットは非致命: 失敗してもフィードバックは静的解析の結果に任せる
  if command -v shfmt >/dev/null 2>&1; then
    shfmt -i 2 -ci -w "$file_path" >/dev/null 2>&1 || true
  fi
  command -v shellcheck >/dev/null 2>&1 || return 0
  out=$(shellcheck "$file_path" 2>&1) && return 0
  log_and_exit "shellcheck が問題を報告しました（$file_path）。修正してください:

$out"
}

lint_markdown() {
  local out escaped
  command -v markdownlint-cli2 >/dev/null 2>&1 || return 0
  # markdownlint-cli2 は引数をglobとして解釈するため、`(` `{` `!` などを
  # 含むパスはそのまま渡すと一致せず「0 files / 0 issues」で無言のexit 0になる。
  # メタ文字をエスケープしてリテラルとして扱わせる。
  escaped=$(printf '%s' "$file_path" | sed -E 's/([][*?{}()!\\])/\\\1/g')
  out=$(cd "$project_dir" && markdownlint-cli2 "$escaped" 2>&1) && return 0
  log_and_exit "markdownlint-cli2 が問題を報告しました（$file_path）。修正してください:

$out"
}

case "$file_path" in
  *.md) lint_markdown ;;
  *) is_shell && lint_shell ;;
esac

exit 0
