#!/usr/bin/env bash
# `*.sh.tmpl` のシェルコードを shellcheck にかける。
#
# chezmoiテンプレートは Goテンプレート構文 `{{ ... }}` を含むため shellcheck が
# そのままではパースできない。ここではテンプレートアクションを無害化した一時ファイルを
# 作り、それを shellcheck に渡す。
#
# `chezmoi execute-template` でレンダリングする方式（Helm の render-then-lint 相当）
# も検討し、実測で比較した上でこちらを採った。`--config` の `[data.chezmoi]` で
# 組み込み変数は上書きできるので「実行マシン依存」は避けられる。それでも除去方式を採る:
#
#   - 検出力は同じだった。WSL / 非WSL+GUI / 非WSL+GUI無し の3変種をレンダリングして
#     静的解析にかけたところ、指摘は除去方式の22件と完全に一致した（差分ゼロ）
#   - 行番号が原文と1:1で保たれる。レンダリングでは trim marker と落ちた分岐で行が
#     ずれ、同じ指摘が変種ごとに別の行番号で出た（例: 同一のSC2069が 71 / 74 / 68 行目、
#     原文は77行目）。PostToolUseフックのフィードバックとしては原文の行番号が要る
#   - `lookPath "gh"` のような PATH 依存の分岐は config で上書きできない。実際、
#     3変種すべてで `{{ else }}` 枝がレンダリングされず、そこのシェルコードは
#     一度も検査されなかった。除去方式なら両枝が残る
#   - 変種行列を人手で保守する必要がない。新しい条件分岐が増えても、
#     行列の更新漏れによる無言の検査漏れが起きない
#   - 懸念されていた「排他的な分岐の連結による偽陽性」（SC2317/SC2034 等）は
#     4ファイルでは1件も出なかった
#
# 行番号を保存すること（行全体がアクションの行は空行に置換、インラインは
# リテラルトークンに置換）が必須要件。ズレると shellcheck の行番号が
# 実ファイルの別の行を指し、フィードバックとして有害になる。
#
# shfmt は対象外。整形結果を一時ファイルから元の `.tmpl` に書き戻す経路が
# 存在しないため、フォーマッタは働き場所がない。実装の都合ではなく原理的な制約。
#
# 注意: `{{ else }}` を持つファイルでは両方の枝が連結された一時ファイルになる。
# 片方の枝で定義した変数をもう片方で使っていても、この検査は素通りする。
#
# 引数でファイルを渡すとそのファイルだけを検査する（pre-commit / PostToolUseフック用）。
# 対象外のファイルは無言でスキップする。
# 引数なしの場合はリポジトリ全体を検査する（CI用）。
set -uo pipefail

status=0
workdir=""

# `.shellcheckrc` はチェック対象ファイルのディレクトリから上へ探索される。
# 一時ファイルは repo 外に置くため、明示的に repo のものを渡さないと
# `disable=SC1091,SC2250,...` が効かず、呼び出し元のCWD次第で厳しさが変わる。
script_dir=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(CDPATH='' cd -- "$script_dir/../.." && pwd)
rcfile="$repo_root/.shellcheckrc"

fail() {
  # $1: ファイル, $2: 行番号, $3: メッセージ
  printf '%s:%s: %s\n' "$1" "$2" "$3" >&2
  status=1
}

# 行全体がテンプレートアクションなら空行に、インラインならリテラルトークンに置換する。
# 複数行にまたがるアクションはこの方式では扱えないので、検出したら失敗させる
# （黙って壊れたシェルを shellcheck に渡すと、意味不明なパースエラーになる）。
strip_template_actions() {
  # $1: 入力ファイル, $2: 出力ファイル
  awk '
    {
      line = $0
      sub(/\r$/, "", line)
      if (line ~ /^[[:space:]]*\{\{[^{}]*\}\}[[:space:]]*$/) { print ""; next }
      while (match(line, /\{\{[^{}]*\}\}/)) {
        line = substr(line, 1, RSTART - 1) "chezmoi_template_value" substr(line, RSTART + RLENGTH)
      }
      if (line ~ /\{\{/ || line ~ /\}\}/) {
        printf "%d\n", NR > "/dev/stderr"
        bad = 1
      }
      print line
    }
    END { if (bad) exit 3 }
  ' "$1" >"$2"
}

# 対象は `.sh.tmpl` かつ shebang を持つファイル。
# ファイル全体を `grep '^#!'` で見ると PowerShell の here-string に埋め込まれた
# shebang を拾うため、先頭数行だけを見る。
has_shebang() {
  head -n 5 "$1" | grep -q '^#!'
}

# shebang からシェル種別を決める。1行目がアクションで潰れると shellcheck は
# 種別を判定できないため、必ず `--shell` を明示的に渡す。
# `.shellcheckrc` の `shell=bash` に任せると `#!/bin/sh` のファイルまで
# bash として検査され、POSIX違反を見逃す（かつ SC2292 が誤って出る）。
detect_shell() {
  local shebang
  shebang=$(head -n 5 "$1" | grep -m1 '^#!')
  case "$shebang" in
    *bash*) printf 'bash' ;;
    *dash*) printf 'dash' ;;
    *ksh*) printf 'ksh' ;;
    *) printf 'sh' ;;
  esac
}

# SC1128（shebangが1行目にない）はアクションを空行化した副作用なので除外する。
# 除外を正当化するには「レンダリング後に shebang が本当に1行目へ来る」ことが要る。
# 除去後の一時ファイルでは判定できない（空行化したアクション行と元からの空行が
# 区別できない）ので、元ファイルを見る。
#
# shebang より前に置けるのは trim marker 付きの行アクション（`{{ ... -}}`）だけ。
# `-}}` は自身の行末改行と後続の空白をまとめて捨てるため、その並びなら shebang が
# 1行目に来る。marker のないアクションは改行を残すので shebang が落ちる。
# check-repo-conventions.sh の規約1 はアクションの「直後」の行しか見ないため、
# 間に空行が挟まる形はそこをすり抜ける。ここで塞ぐ。
verify_shebang_position() {
  local file="$1" line lineno trimmed=0
  local -a lines=()
  mapfile -t lines <"$file"
  for lineno in "${!lines[@]}"; do
    line="${lines[lineno]%$'\r'}"
    lineno=$((lineno + 1))
    [[ $line == '#!'* ]] && return 0
    if [[ $line =~ ^[[:space:]]*\{\{[^{}]*-\}\}[[:space:]]*$ ]]; then
      trimmed=1
      continue
    fi
    if [[ -z ${line//[[:space:]]/} ]] && [[ $trimmed -eq 1 ]]; then
      # 直前の `-}}` に食われるので残らない
      continue
    fi
    fail "$file" "$lineno" "shebang より前にレンダリング結果へ残る行がある（shebang が1行目に来ない）。行アクションには trim marker（\`-}}\`）を付けること"
    return 1
  done
  return 0
}

check_file() {
  local file="$1"
  [[ -f $file ]] || return 0
  [[ $file == *.sh.tmpl ]] || return 0
  # 無言でスキップすると、先頭にコメント塊を足しただけでファイルが
  # 検査対象から静かに外れる。それはこの検査が塞ごうとしている穴そのものなので
  # エラーにする（対象外にしたいなら拡張子を `.sh.tmpl` にしないこと）
  if ! has_shebang "$file"; then
    fail "$file" 1 "\`.sh.tmpl\` なのに先頭5行に shebang がない（検査対象にならない）"
    return 0
  fi

  local base stripped shell out bad_lines
  base=$(basename "$file")
  stripped="$workdir/$base.sh"

  bad_lines=$(strip_template_actions "$file" "$stripped" 2>&1)
  if [[ -n $bad_lines ]]; then
    local lineno
    for lineno in $bad_lines; do
      fail "$file" "$lineno" "複数行にまたがるテンプレートアクションは検査できない。1行に収めること"
    done
    return 0
  fi

  verify_shebang_position "$file" || return 0

  shell=$(detect_shell "$file")
  if out=$(shellcheck --rcfile="$rcfile" --shell="$shell" --exclude=SC1128 "$stripped" 2>&1); then
    return 0
  fi
  # 報告は一時ファイル名で出る。実ファイル名に戻さないとクリックしても
  # 存在しないファイルを指す。行番号は保存済みなのでそのまま使える。
  printf '%s\n' "${out//$stripped/$file}" >&2
  status=1
}

collect_default_targets() {
  git -C "$repo_root" ls-files -- '*.sh.tmpl' 2>/dev/null ||
    find "$repo_root" -name '*.sh.tmpl' -not -path '*/.git/*'
}

main() {
  local file
  command -v shellcheck >/dev/null 2>&1 || {
    printf 'check-tmpl-shell: shellcheck が見つからない\n' >&2
    return 1
  }
  workdir=$(mktemp -d) || return 1
  trap 'rm -rf "$workdir"' EXIT

  if [[ $# -gt 0 ]]; then
    for file in "$@"; do
      check_file "$file"
    done
  else
    local -a targets=()
    mapfile -t targets < <(collect_default_targets || true)
    for file in "${targets[@]}"; do
      check_file "$repo_root/${file#"$repo_root"/}"
    done
  fi

  if [[ $status -ne 0 ]]; then
    printf '\n`.sh.tmpl` のシェルコードに shellcheck の指摘がある。詳細は CLAUDE.md を参照。\n' >&2
  fi
  return "$status"
}

main "$@"
exit "$?"
