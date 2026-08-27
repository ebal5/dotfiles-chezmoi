#!/usr/bin/env bash
# 共有設定ファイル（dot_claude/*.src）に、マシン固有・組織固有の値が
# 混入したまま commit されるのを防ぐ。
#
# これらのファイルは ~/.claude/ のシンボリックリンク先であり、
# Claude Code や herdr などの外部ツールが直接書き込む。
# public リポジトリなので、書き込まれた内容はそのまま公開されうる。
#
# 判定は allowlist 方式。禁止したい顧客名をリポジトリに書くとそれ自体が
# 流出になるため、既知の公開ホスト／オーナー以外を弾く形にし、
# 固有名詞のリストはマシンローカル（DENYLIST）に置く。
set -euo pipefail

# 公開して差し支えない GitHub オーナー
ALLOWED_OWNERS="ebal5 anthropics oraios joaojacome"
# 公開して差し支えないホスト名
ALLOWED_HOSTS="github.com raw.githubusercontent.com claude.ai docs.anthropic.com
json.schemastore.org mcp.context7.com nixos.org starship.rs chezmoi.io"
# マシンローカルの追加禁止語（1行1パターン、存在する場合のみ適用）
DENYLIST="${HOME}/.config/local/shared-settings-denylist"

# 既定の対象はスクリプトの位置から解決する。cwd 基準の相対パスにすると、
# リポジトリルート以外から実行したときに「対象が1つも無い」で黙って exit 0 し、
# 検査したつもりの素通りになる（normalize-shared-settings.sh と同じ扱い）
SCRIPT_PATH=$(readlink -f -- "${BASH_SOURCE[0]}")
REPO_ROOT=$(cd -- "$(dirname -- "$SCRIPT_PATH")/../.." && pwd)
DEFAULT_TARGETS=(
  "$REPO_ROOT/dot_claude/settings.json.src"
  "$REPO_ROOT/dot_claude/dot_mcp.json.src"
)

status=0

fail() {
  printf '%s:%s: %s\n' "$1" "$2" "$3" >&2
  status=1
}

# 前後を空白で挟み、"$list" == *" $needle "* の形で照合できるようにする
OWNER_SET=" ${ALLOWED_OWNERS//[[:space:]]/ } "
HOST_SET=" ${ALLOWED_HOSTS//[[:space:]]/ } "

check_line() {
  local file="$1" lineno="$2" line="$3"
  local owner host pattern

  # 1. マシン固有の絶対パス
  if [[ "$line" =~ (/home/|/Users/|/root/|[A-Za-z]:\\Users\\) ]]; then
    fail "$file" "$lineno" "マシン固有の絶対パス: ${BASH_REMATCH[1]}"
  fi

  # 2. allowlist 外の GitHub オーナー
  if [[ "$line" =~ github\.com[:/]([A-Za-z0-9_.-]+)/ ]]; then
    owner="${BASH_REMATCH[1]}"
    if [[ "$OWNER_SET" != *" $owner "* ]]; then
      fail "$file" "$lineno" "未知の GitHub オーナー: $owner"
    fi
  fi

  # 3. allowlist 外のホスト名
  for host in $(grep -oE '\b[A-Za-z0-9][A-Za-z0-9-]*(\.[A-Za-z0-9-]+)+\.(com|net|org|io|dev|ai|jp|cloud|app|me)\b' <<<"$line" || true); do
    if [[ "$HOST_SET" != *" $host "* ]]; then
      fail "$file" "$lineno" "未知のホスト名: $host"
    fi
  done

  # 4. マシンローカルの禁止語
  if [[ -f "$DENYLIST" ]]; then
    while IFS= read -r pattern; do
      if [[ -z "$pattern" || "$pattern" == \#* ]]; then
        continue
      fi
      if grep -qiF -- "$pattern" <<<"$line"; then
        fail "$file" "$lineno" "ローカル denylist に一致"
      fi
    done <"$DENYLIST"
  fi
}

check_file() {
  local file="$1" index
  local -a lines=()
  mapfile -t lines <"$file"
  for index in "${!lines[@]}"; do
    check_line "$file" "$((index + 1))" "${lines[index]}"
  done
}

targets=("$@")
if [[ ${#targets[@]} -eq 0 ]]; then
  if [[ ! -d "$REPO_ROOT/dot_claude" ]]; then
    printf '既定の対象を解決できない（%s に dot_claude が無い）。スクリプトを .github/scripts/ から移していないか確認すること。\n' "$REPO_ROOT" >&2
    exit 1
  fi
  targets=("${DEFAULT_TARGETS[@]}")
fi

for target in "${targets[@]}"; do
  if [[ -f "$target" ]]; then
    check_file "$target"
  fi
done

if [[ $status -ne 0 ]]; then
  cat >&2 <<'MSG'

共有設定にマシン固有・組織固有の値が入っている。
これらのファイルは ~/.claude/ のシンボリックリンク先で、外部ツールが直接書き込む。
該当箇所を削除するか、環境非依存の形（~/.scripts/ のラッパー等）に置き換えること。
正当な追加であれば .github/scripts/check-shared-settings.sh の allowlist を更新する。
MSG
fi

exit "$status"
