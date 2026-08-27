#!/usr/bin/env bash
# 共有設定ファイル（dot_claude/*.src）のキー順を正規化する。
#
# `~/.claude/settings.json` と `~/.claude/.mcp.json` は `dot_claude/*.src` への
# シンボリックリンクで、Claude Code 自身や herdr などの外部ツールが直接書き込む。
# 書き戻しの際にキー順が変わることがあり、値が何も変わっていなくても
# 「キーが入れ替わっただけ」の差分が出る。
#
# その差分自体は無害だが、混ざると本当に変わったキーが埋もれる。このリポジトリは
# public で、組織固有値の混入を毎回 `git diff` で目視確認する運用
# （.claude/rules/security.md）なので、埋もれること自体が問題になる。
#
# そこで `jq --sort-keys` で常に同じ順序に固定し、差分を値が変わったキーだけにする。
# 検査ではなく整形なのが check-shared-settings.sh との違い。
#
# 使い方:
#   normalize-shared-settings.sh [FILE...]           # 正規化して書き戻す（既定）
#   normalize-shared-settings.sh --check [FILE...]   # 正規化済みかを検査する（CI・pre-commit用）
#
# 引数なしの場合は DEFAULT_TARGETS を対象にする。
set -euo pipefail

# 既定の対象はスクリプトの位置からリポジトリルートを求めて解決する。cwd 依存だと、
# ルート以外から実行したときに「対象が1つも無い」で黙って成功してしまう
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
DEFAULT_TARGETS=("dot_claude/settings.json.src" "dot_claude/dot_mcp.json.src")

# 複数ドキュメントや空入力を弾いてから整形する。jq は `{"a":1}{"b":2}` のような
# ストリームも空入力も黙って通すため、そのまま書き戻すと壊れたファイルが残り、
# しかも再実行すると `--check` が通ってしまう
JQ_PROGRAM='if length == 1 then .[0] else error("JSON ドキュメントが \(length) 個ある（1個であること）") end'

check_only=0
status=0
unnormalized=0

usage() {
  cat <<'MSG'
Usage: normalize-shared-settings.sh [--check] [FILE...]
  (フラグなし)  キー順を正規化して書き戻す
  --check       正規化済みかを検査する（書き換えない）
MSG
}

# オプションは位置に依存させない。`FILE --check` を「--check という名前のファイル」と
# 解釈すると、検査のつもりの実行がファイルを書き換えてしまう
declare -a targets=()
parsing_options=1
for arg in "$@"; do
  if [[ $parsing_options -eq 1 ]]; then
    case "$arg" in
      --check)
        check_only=1
        continue
        ;;
      -h | --help)
        usage
        exit 0
        ;;
      --)
        parsing_options=0
        continue
        ;;
      -?*)
        printf '不明なオプション: %s\n' "$arg" >&2
        usage >&2
        exit 2
        ;;
      *) ;;
    esac
  fi
  targets+=("$arg")
done

# jq が無いときに黙ってスキップすると、正規化されていないファイルが
# 「フックを通った」顔でコミットされる。整形が目的なので落とす方が正しい
if ! command -v jq >/dev/null 2>&1; then
  printf 'jq が見つからない。共有設定のキー順を正規化できない（Nix環境なら flake.nix に含まれている）。\n' >&2
  exit 1
fi

tmpdir=$(mktemp -d)
staging=""
# shellcheck disable=SC2329 # 直接呼ばず trap から起動する
cleanup() {
  rm -rf -- "$tmpdir"
  if [[ -n $staging ]]; then
    rm -f -- "$staging"
  fi
  return 0
}
trap cleanup EXIT

fail() {
  # $1: ファイル, $2: メッセージ
  printf '%s: %s\n' "$1" "$2" >&2
  status=1
}

normalize_file() {
  local file="$1"
  local normalized="$tmpdir/normalized.json" jq_err="$tmpdir/jq.err"

  if ! jq --slurp --sort-keys --indent 2 "$JQ_PROGRAM" -- "$file" >"$normalized" 2>"$jq_err"; then
    fail "$file" "JSON として読めない"
    cat -- "$jq_err" >&2
    return 0
  fi

  # jq が異常終了せずに空を出すことはこの時点で無いはずだが、書き戻す直前の
  # 最後の砦として見る。空を書き戻すと共有設定が丸ごと消える
  if [[ ! -s "$normalized" ]]; then
    fail "$file" "正規化結果が空になった"
    return 0
  fi

  if cmp -s -- "$normalized" "$file"; then
    return 0
  fi

  if [[ $check_only -eq 1 ]]; then
    fail "$file" "正規化されていない（キー順、またはJSONエスケープの表現が異なる）"
    unnormalized=1
    # 差分が無い場合は上の cmp で除いてあるので、diff は必ず非ゼロで返る
    diff -u -- "$file" "$normalized" >&2 || true
    return 0
  fi

  # 同じディレクトリに書いてから mv する。`>` で直接上書きすると、書き込みが
  # 途中で失敗した（ディスクフル等）ときに元の内容が失われる。
  # 名前を決め打ちにせず mktemp で作るのは、その名前で先回りして置かれた
  # シンボリックリンクを `>` が辿り、リンク先を壊すのを防ぐため
  if ! staging=$(mktemp -- "$file.normalize.XXXXXX"); then
    staging=""
    fail "$file" "一時ファイルを作れなかった（元の内容は変更していない）"
    return 0
  fi
  # mktemp は 600 で作るので、元のパーミッションに合わせ直す
  if ! chmod --reference="$file" -- "$staging" || ! cat -- "$normalized" >"$staging"; then
    fail "$file" "一時ファイルへの書き込みに失敗した（元の内容は変更していない）"
    rm -f -- "$staging"
    staging=""
    return 0
  fi
  if ! mv -f -- "$staging" "$file"; then
    fail "$file" "書き戻しに失敗した（元の内容は変更していない）"
    rm -f -- "$staging"
    staging=""
    return 0
  fi
  staging=""
  printf '%s: キー順を正規化した\n' "$file"
}

explicit_targets=1
if [[ ${#targets[@]} -eq 0 ]]; then
  explicit_targets=0
  # 相対パスのまま扱えるようルートへ移る。引数で明示された場合は移らないので、
  # 呼び出し側の cwd 基準の相対パスがそのまま通る
  cd -- "$REPO_ROOT"
  targets=("${DEFAULT_TARGETS[@]}")
fi

for target in "${targets[@]}"; do
  if [[ -L "$target" ]]; then
    # リンク先を書き換えてしまう。共有設定はいずれも実体ファイル
    fail "$target" "シンボリックリンクは対象外"
    continue
  fi
  if [[ ! -f "$target" ]]; then
    if [[ $explicit_targets -eq 1 ]]; then
      # 引数のtypoを無言で通すと、正規化したつもりの素通りになる
      fail "$target" "ファイルが存在しない（またはディレクトリ）"
    fi
    # 既定の対象が無いのは、そのファイルを消した正当な変更でありうる。
    # check-shared-settings.sh と同じく黙って飛ばす
    continue
  fi
  normalize_file "$target"
done

if [[ $unnormalized -eq 1 ]]; then
  cat >&2 <<'MSG'

共有設定が正規化されていない。
`.github/scripts/normalize-shared-settings.sh` を実行し、`git diff` で中身を確認してから
`git add` すること。ステージ済みの内容だけが崩れている場合、スクリプトは何も書き換えず
`git add` し直すこと自体が修正になる。
MSG
fi

exit "$status"
