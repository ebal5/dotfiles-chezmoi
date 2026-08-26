#!/usr/bin/env bash
# リポジトリ固有の規約を静的に検査する。
#
# CLAUDE.md / .claude/rules/ に散らばっていた「守るべき決まり」のうち、
# 機械的に判定できるものだけをここに集約する。判断が必要なもの
# （ツール管理方針の判定基準など）は対象外。
#
# 引数でファイルを渡すとそのファイルだけを検査する（pre-commit / PostToolUseフック用）。
# 引数なしの場合はリポジトリ全体を検査する（CI用）。
set -uo pipefail

status=0

fail() {
  # $1: ファイル, $2: 行番号, $3: メッセージ
  printf '%s:%s: %s\n' "$1" "$2" "$3" >&2
  status=1
}

# CRLF対策。行末の CR を落とす
strip_cr() {
  printf '%s' "${1%$'\r'}"
}

# 規約1: chezmoiテンプレートの先頭に条件分岐を置く場合、shebangが直後に続くなら
#        trim marker（`-}}`）が必須。付け忘れるとshebangが2行目に落ちて実行に失敗する。
#
# 判定は「テンプレートアクションの直後の行が shebang か」で行う。
# ファイル全体を `grep '^#!'` で見ると、PowerShellのhere-stringに埋め込まれた
# shebangまで拾って誤検知する。
check_template_trim_marker() {
  local file="$1" line action_end="" i
  local -a lines=()
  mapfile -t lines <"$file"
  [[ ${#lines[@]} -gt 0 ]] || return 0

  line=$(strip_cr "${lines[0]}")
  # 先頭行がテンプレートアクションで始まっていなければ対象外
  # （インデントされていてもレンダリング後に空白が残るので同じ扱いにする）
  [[ $line =~ ^[[:space:]]*\{\{ ]] || return 0

  # アクションが閉じる行を探す（複数行にまたがる場合がある）
  for i in "${!lines[@]}"; do
    line=$(strip_cr "${lines[i]}")
    if [[ $line =~ \}\}[[:space:]]*$ ]]; then
      action_end="$i"
      break
    fi
  done
  # 閉じていない、または閉じた行の後ろに続きがある場合は対象外
  [[ -n $action_end ]] || return 0

  # アクション直後の行が shebang でなければ、行がずれても実害はない
  local next_line
  next_line=$(strip_cr "${lines[action_end + 1]-}")
  [[ $next_line == '#!'* ]] || return 0

  line=$(strip_cr "${lines[action_end]}")
  [[ $line =~ -\}\}[[:space:]]*$ ]] && return 0

  fail "$file" "$((action_end + 1))" "テンプレートアクションに trim marker がない（\`-}}\` にすること）。shebangが次の行に落ちて実行に失敗する"
}

# 規約2: shim定義は `runner:package[:alias]` 形式。`@`を含むpackageはalias必須
#        （run_after_generate_shims.sh.tmpl がERRORを出してスキップするため）。
check_shim_definitions() {
  local file="$1" line raw lineno runner rest package alias
  local -a lines=()
  mapfile -t lines <"$file"
  for lineno in "${!lines[@]}"; do
    raw="${lines[lineno]}"
    line=$(strip_cr "$raw")
    lineno=$((lineno + 1))
    [[ -z $line || $line == \#* ]] && continue

    # generatorは行をそのまま使うため、前後の空白はshim名に混入する
    if [[ $line =~ ^[[:space:]] ]] || [[ $line =~ [[:space:]]$ ]]; then
      fail "$file" "$lineno" "行の前後に空白がある（生成されるshim名に混入する）: [$line]"
      continue
    fi
    if [[ $line != *:* ]]; then
      fail "$file" "$lineno" "形式は runner:package[:alias]。コロンがない: $line"
      continue
    fi

    runner="${line%%:*}"
    rest="${line#*:}"
    if [[ $rest == *:* ]]; then
      package="${rest%%:*}"
      alias="${rest#*:}"
    else
      package="$rest"
      alias=""
    fi

    if [[ $runner != "uvx" && $runner != "pnpm" ]]; then
      fail "$file" "$lineno" "runner は uvx か pnpm のみ: $runner"
      continue
    fi
    if [[ -z $package ]]; then
      fail "$file" "$lineno" "package が空: $line"
      continue
    fi
    if [[ $package == *@* && -z $alias ]]; then
      fail "$file" "$lineno" "\`@\`を含むpackageはalias必須（generatorがERRORを出してスキップする）: $package"
    fi
    if [[ -n $alias && ! $alias =~ ^[A-Za-z0-9_.-]+$ ]]; then
      fail "$file" "$lineno" "alias に使えない文字が含まれる: [$alias]"
    fi
  done
}

check_file() {
  local file="$1"
  if [[ ! -f $file ]]; then
    # 引数のtypoやディレクトリ指定を無言で通すと、検査したつもりの素通りになる
    fail "$file" 0 "ファイルが存在しない（またはディレクトリ）"
    return 0
  fi

  case "$file" in
    */shim-definitions | shim-definitions) check_shim_definitions "$file" ;;
    *.tmpl) check_template_trim_marker "$file" ;;
    *) ;;
  esac
}

collect_default_targets() {
  git ls-files -- '*.tmpl' 'dot_config/shim-definitions' 2>/dev/null ||
    find . -name '*.tmpl' -not -path './.git/*'
}

main() {
  local file
  if [[ $# -gt 0 ]]; then
    for file in "$@"; do
      check_file "$file"
    done
  else
    local -a targets=()
    mapfile -t targets < <(collect_default_targets || true)
    for file in "${targets[@]}"; do
      check_file "$file"
    done
  fi

  if [[ $status -ne 0 ]]; then
    printf '\nリポジトリ固有の規約に違反している。詳細は CLAUDE.md と .claude/rules/ を参照。\n' >&2
  fi
  return "$status"
}

main "$@"
exit "$?"
