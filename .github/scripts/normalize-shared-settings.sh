#!/usr/bin/env bash
# 共有設定ファイル（dot_claude/*.src）のキー順を正規化する。
#
# `~/.claude/settings.json` と `~/.claude/.mcp.json` は `dot_claude/*.src` への
# シンボリックリンクで、Claude Code 自身や herdr などの外部ツールが直接書き込む。
# 書き戻し時のキー順は安定せず、値が何も変わっていなくても「キーが入れ替わった
# だけ」の差分が出る。
#
# その差分自体は無害だが、混ざると本当に変わったキーが埋もれる。このリポジトリは
# public で、組織固有値の混入を毎回 `git diff` で目視確認する運用
# （.claude/rules/security.md）なので、埋もれること自体が問題になる。
#
# そこで `jq --sort-keys` で常に同じ順序に固定し、差分を値が変わったキーだけにする。
# 検査ではなく整形なのが check-shared-settings.sh との違いで、既定は書き戻し。
#
# 使い方:
#   normalize-shared-settings.sh [FILE...]           # 正規化して書き戻す（既定）
#   normalize-shared-settings.sh --check [FILE...]   # 正規化済みかを検査する（CI用）
#
# 引数なしの場合は DEFAULT_TARGETS を対象にする。
set -euo pipefail

DEFAULT_TARGETS="dot_claude/settings.json.src dot_claude/dot_mcp.json.src"

check_only=0
status=0

usage() {
  cat <<'MSG'
Usage: normalize-shared-settings.sh [--check] [FILE...]
  (フラグなし)  キー順を正規化して書き戻す
  --check       正規化済みかを検査する（書き換えない）
MSG
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      check_only=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      printf '不明なオプション: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
    *) break ;;
  esac
done

# jq が無いときに黙ってスキップすると、正規化されていないファイルが
# 「フックを通った」顔でコミットされる。整形が目的なので落とす方が正しい
if ! command -v jq >/dev/null 2>&1; then
  printf 'jq が見つからない。共有設定のキー順を正規化できない（Nix環境なら flake.nix に含まれている）。\n' >&2
  exit 1
fi

tmpdir=$(mktemp -d)
trap 'rm -rf -- "$tmpdir"' EXIT

fail() {
  # $1: ファイル, $2: メッセージ
  printf '%s: %s\n' "$1" "$2" >&2
  status=1
}

normalize_file() {
  local file="$1"
  local normalized="$tmpdir/normalized.json" jq_err="$tmpdir/jq.err"

  if ! jq --sort-keys --indent 2 . "$file" >"$normalized" 2>"$jq_err"; then
    fail "$file" "JSON として読めない"
    cat -- "$jq_err" >&2
    return 0
  fi

  # jq は空／空白だけの入力を「出力なし・exit 0」で通す。そのまま書き戻すと
  # 共有設定が空になるので、書き換える前に落とす
  if [[ ! -s "$normalized" ]]; then
    fail "$file" "正規化結果が空になった（中身が JSON ではない）"
    return 0
  fi

  if cmp -s -- "$normalized" "$file"; then
    return 0
  fi

  if [[ $check_only -eq 1 ]]; then
    fail "$file" "キー順が正規化されていない"
    # 差分が無いときの exit 0 は上の cmp で除いてあるので、ここは常に 1 を返す
    diff -u -- "$file" "$normalized" >&2 || true
    return 0
  fi

  # 内容だけを差し替える。`mv` だとパーミッションと inode が変わる
  cat -- "$normalized" >"$file"
  printf '%s: キー順を正規化した\n' "$file"
}

targets=("$@")
if [[ ${#targets[@]} -eq 0 ]]; then
  # shellcheck disable=SC2206 # 空白区切りの固定リストなので分割してよい
  targets=($DEFAULT_TARGETS)
fi

for target in "${targets[@]}"; do
  if [[ ! -f "$target" ]]; then
    # 引数のtypoを無言で通すと、正規化したつもりの素通りになる
    fail "$target" "ファイルが存在しない（またはディレクトリ）"
    continue
  fi
  normalize_file "$target"
done

if [[ $status -ne 0 && $check_only -eq 1 ]]; then
  cat >&2 <<'MSG'

共有設定のキー順が正規化されていない。
`.github/scripts/normalize-shared-settings.sh` を実行し、その差分をコミットすること。
MSG
fi

exit "$status"
