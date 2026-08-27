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

# パターンの前後の空白を落とす処理で bash の `[[:space:]]` を使う。これは
# ロケール依存で、UTF-8ロケールでないと全角スペース (U+3000) に一致しない。
# chezmoi 側は `bytes.TrimSpace`（Unicode対応）なので、固定しないと
# 「全角スペース + パターン」の行でローカルとCIの結果が食い違う。
# `C.UTF-8` が無い環境ではCにフォールバックしてASCIIのみになるが、
# 見逃す方向なのでCIが最後に捕まえる
export LC_ALL=C.UTF-8

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

  # アクションの後ろにある空行を読み飛ばして shebang を探す。
  # 直後の行だけを見ると `{{ if }}` / 空行 / shebang の並びを取りこぼす
  # （空行はレンダリング結果に残るので、shebangは1行目に来ない）。
  local next_line i2=$((action_end + 1))
  while :; do
    next_line=$(strip_cr "${lines[i2]-}")
    [[ -n ${next_line//[[:space:]]/} ]] && break
    [[ $i2 -ge ${#lines[@]} ]] && return 0
    i2=$((i2 + 1))
  done
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

# 規約3: markdownlint-cli2 のバージョンは dot_config/shim-definitions を単一情報源とする。
#
# `.markdownlint-cli2.yaml` で MD060 の style を明示しており、ルールの挙動が
# バージョンに依存する。CIとローカルで版が食い違うと「ローカルで通ったのに
# CIで落ちる」が起きる。固定箇所を2つ持って一致を検査するのではなく、
# CI側が shim 定義から抽出することで、そもそもドリフトを起こしえなくする。
#
# その設計がなし崩しにされるのを防ぐため、次の3点を検査する:
#   1. shim 定義でバージョンが固定されていること
#   2. linter.yaml が markdownlint-cli2 のバージョンをハードコードしていないこと
#      （「簡潔にしよう」と直書きに戻されると単一情報源が黙って崩れる）
#   3. linter.yaml が shim 定義を参照していること
MARKDOWNLINT_PKG="markdownlint-cli2"
SHIM_DEFS_FILE="dot_config/shim-definitions"
LINTER_WORKFLOW_FILE=".github/workflows/linter.yaml"

# shim定義から `runner:<package>[@<version>][:alias]` を探す。
# 出力: "<行番号> <バージョン>"。行が無ければ "0"、バージョン未固定なら "<行番号>" のみ
find_shim_version() {
  local pkg="$1" file="$2" line lineno rest
  local -a lines=()
  mapfile -t lines <"$file"
  for lineno in "${!lines[@]}"; do
    line=$(strip_cr "${lines[lineno]}")
    [[ -z $line || $line == \#* ]] && continue
    # runner を落として package 以降だけを見る
    rest="${line#*:}"
    if [[ $rest == "$pkg" || $rest == "$pkg:"* ]]; then
      printf '%s\n' "$((lineno + 1))"
      return 0
    fi
    if [[ $rest == "$pkg@"* ]]; then
      rest="${rest#"$pkg@"}"
      printf '%s %s\n' "$((lineno + 1))" "${rest%%:*}"
      return 0
    fi
  done
  printf '0\n'
}

check_markdownlint_version_source() {
  local shim_lineno shim_ver line lineno rest
  local refs_shim_defs=0 mentions_pkg=0 hardcoded_lineno=0
  local -a lines=()

  if [[ ! -f $SHIM_DEFS_FILE ]]; then
    fail "$SHIM_DEFS_FILE" 0 "バージョンの単一情報源が無い"
    return 0
  fi

  read -r shim_lineno shim_ver < <(find_shim_version "$MARKDOWNLINT_PKG" "$SHIM_DEFS_FILE" || true)
  if [[ $shim_lineno -eq 0 ]]; then
    fail "$SHIM_DEFS_FILE" 0 "$MARKDOWNLINT_PKG の shim 定義が無い。CIもここからバージョンを読むため、消すとCIが壊れる"
  elif [[ -z $shim_ver ]]; then
    fail "$SHIM_DEFS_FILE" "$shim_lineno" "$MARKDOWNLINT_PKG のバージョンが固定されていない（\`pnpm:$MARKDOWNLINT_PKG@<version>:$MARKDOWNLINT_PKG\` の形にすること）"
  fi

  if [[ ! -f $LINTER_WORKFLOW_FILE ]]; then
    fail "$LINTER_WORKFLOW_FILE" 0 "$MARKDOWNLINT_PKG を実行するワークフローが無い"
    return 0
  fi

  mapfile -t lines <"$LINTER_WORKFLOW_FILE"
  for lineno in "${!lines[@]}"; do
    line=$(strip_cr "${lines[lineno]}")
    # コメント行は除外する。「shim定義から抽出する」と書いたコメントだけが残り、
    # 実行される側は非固定インストールに戻っている、を通してしまうため
    [[ $line =~ ^[[:space:]]*# ]] && continue
    [[ $line == *"$SHIM_DEFS_FILE"* ]] && refs_shim_defs=1
    [[ $line == *"$MARKDOWNLINT_PKG"* ]] || continue
    mentions_pkg=1
    # packageは正規表現ではなく文字列一致で切り出すため、`@`を含む
    # scoped package を対象にしても壊れない
    [[ $line == *"$MARKDOWNLINT_PKG@"* ]] || continue
    rest="${line#*"$MARKDOWNLINT_PKG@"}"
    # `@${version}` のような変数参照ではなく、数字で始まる直書きだけを拾う
    [[ $rest =~ ^[0-9] ]] || continue
    [[ $hardcoded_lineno -eq 0 ]] && hardcoded_lineno=$((lineno + 1))
  done

  if [[ $mentions_pkg -eq 0 ]]; then
    fail "$LINTER_WORKFLOW_FILE" 0 "$MARKDOWNLINT_PKG への言及が無い。markdownlint ジョブが消えている"
    return 0
  fi
  if [[ $hardcoded_lineno -ne 0 ]]; then
    fail "$LINTER_WORKFLOW_FILE" "$hardcoded_lineno" "$MARKDOWNLINT_PKG のバージョンが直書きされている。$SHIM_DEFS_FILE から抽出すること（固定箇所を1つに保つ）"
  fi
  if [[ $refs_shim_defs -eq 0 ]]; then
    fail "$LINTER_WORKFLOW_FILE" 0 "$SHIM_DEFS_FILE を参照していない。$MARKDOWNLINT_PKG のバージョンはそこから抽出すること（固定箇所を1つに保つ）"
  fi
}

# 規約4: `.chezmoiignore` / `.chezmoiremove` のパターンは**ターゲットパス**
#        （ホーム上での名前）で書く。chezmoi はソース名ではなくターゲットパスに
#        マッチさせるため、`executable_once_setup_ubuntu.sh.tmpl` のように
#        ソース名で書くと何にもマッチせず、除外したつもりのファイルが
#        ホームに展開される（#217）。しかも何のエラーも出ない。
#
# 判定はパス要素の先頭プレフィックスと `.tmpl` サフィックスで行う。
# `once_` / `onchange_` / `before_` / `after_` は含めない。これらは `run_` の
# 後ろに付く修飾で、単体ではターゲットパスとして正しい
# （`executable_once_setup_ubuntu.sh.tmpl` のターゲットは `once_setup_ubuntu.sh`）。
#
# 誤検知しうるターゲット名がある。`.ssh/private_key` のように、たまたま
# プレフィックスと同じ綴りで始まる実在のファイル名や、`literal_` で
# エスケープされたターゲット名（ソース `literal_dot_foo` のターゲットは
# `dot_foo`）は原理的に区別がつかない。その場合は行末に
# `# chezmoi-target-ok` を付けて明示的に通すこと。chezmoi 側はコメントとして
# 捨てるのでパターンには影響しない。
#
# モデル化していない範囲: trim marker で行が連結される場合。
# `# note {{ if true -}}` の次行は、レンダリング後には行頭 `#` のコメントに
# 吸収されてパターンでなくなるが、この検査は行単位で見るため拾ってしまう。
CHEZMOI_SOURCE_PREFIXES=(
  create_ dot_ empty_ encrypted_ exact_ executable_ external_
  literal_ modify_ private_ readonly_ remove_ run_ symlink_
)
# ソース名にしか現れないサフィックス（chezmoi.go の TemplateSuffix / literalSuffix）
CHEZMOI_SOURCE_SUFFIXES=(.tmpl .literal)
CHEZMOI_TARGET_OK_MARKER="chezmoi-target-ok"

check_chezmoi_target_paths() {
  local file="$1" raw line lineno pattern component prefix suffix
  local -a lines=() components=()
  mapfile -t lines <"$file"
  for lineno in "${!lines[@]}"; do
    raw=$(strip_cr "${lines[lineno]}")
    lineno=$((lineno + 1))
    # BOM を落とす。付いていると1行目だけ検査をすり抜ける
    raw="${raw#$'\xef\xbb\xbf'}"
    # 誤検知を明示的に通すための逃がし。行末のコメントとして書かれた場合だけ
    # 効かせる。単なる部分一致にすると、マーカーと同じ綴りを含むパターン
    # （`.config/chezmoi-target-ok/dot_trap`）まで黙って通してしまう
    [[ $raw =~ (^|[[:space:]])#[[:space:]]*${CHEZMOI_TARGET_OK_MARKER}[[:space:]]*$ ]] && continue

    # 1. テンプレートアクションを外す。`.chezmoiignore` はレンダリングしてから
    #    パースされるため、`{{ if … }}pattern{{ end }}` の1行形式も有効で、
    #    行ごと読み飛ばすとその中のパターンを見逃す。
    #    複数行にまたがるアクションは断片が残るが、パターンとしては何にも
    #    該当しないので誤検知にはならない
    # 2. コメントを落とす。chezmoi は行頭または空白の後ろの `#` 以降を
    #    コメントとして捨てる（sourcestate.go の commentRx）。ここで同じ規則で
    #    落とさないと、`.zshrc # 旧名は dot_zshrc.tmpl` のような正しい行を
    #    ソース名と誤判定する
    # `LC_ALL=C` は必須。chezmoi の commentRx は Go の `\s`（ASCIIのみ）だが、
    # sed の `[[:space:]]` はロケール依存で、CIランナーの `C.UTF-8` では
    # 全角スペース (U+3000) にも一致する。揃えないと「全角スペース + `#`」の行で
    # chezmoi と判定が食い違い、しかもローカルとCIでも結果が変わる
    line=$(LC_ALL=C sed -E -e 's/\{\{[^{}]*\}\}//g' -e 's/(^|[[:space:]])#.*$//' <<<"$raw")
    # 前後の空白を落とす（パターンの一部ではない）
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [[ -z $line ]] && continue

    pattern="${line#!}"    # 否定パターンの `!`
    pattern="${pattern%/}" # ディレクトリ指定の末尾スラッシュ
    [[ -z $pattern ]] && continue

    for suffix in "${CHEZMOI_SOURCE_SUFFIXES[@]}"; do
      [[ $pattern == *"$suffix" ]] || continue
      fail "$file" "$lineno" "ソース名で書かれている（\`$suffix\` はターゲットパスには現れない）。ターゲットパスで書くこと: $line"
      continue 2
    done

    IFS='/' read -r -a components <<<"$pattern"
    for component in "${components[@]}"; do
      for prefix in "${CHEZMOI_SOURCE_PREFIXES[@]}"; do
        [[ $component == "$prefix"* ]] || continue
        fail "$file" "$lineno" "ソース名で書かれている（\`$prefix\` はchezmoiのソース名プレフィックス）。ターゲットパスで書くこと: $line"
        break 2
      done
    done
  done
}

check_file() {
  local file="$1"
  if [[ ! -f $file ]]; then
    # 引数のtypoやディレクトリ指定を無言で通すと、検査したつもりの素通りになる
    fail "$file" 0 "ファイルが存在しない（またはディレクトリ）"
    return 0
  fi

  # `.chezmoiignore.tmpl` は `*.tmpl` にも該当するため、先に判定して両方を通す。
  # chezmoi はサブディレクトリの `.chezmoiignore` も読む（`.` 始まりの
  # ディレクトリは走査対象外）ので、ルート直下だけを見ない
  case "$(basename -- "$file")" in
    .chezmoiignore | .chezmoiignore.tmpl | .chezmoiremove | .chezmoiremove.tmpl)
      check_chezmoi_target_paths "$file"
      ;;
    *) ;;
  esac

  case "$file" in
    */shim-definitions | shim-definitions) check_shim_definitions "$file" ;;
    *.tmpl) check_template_trim_marker "$file" ;;
    *) ;;
  esac
}

collect_default_targets() {
  git ls-files -- '*.tmpl' 'dot_config/shim-definitions' \
    ':(glob)**/.chezmoiignore' ':(glob)**/.chezmoiremove' 2>/dev/null ||
    find . \( -name '*.tmpl' -o -name '.chezmoiignore' -o -name '.chezmoiremove' \) -not -path './.git/*'
}

# バージョンの単一情報源はファイル単位ではなくファイル間の不変条件なので、
# 引数にどちらか一方でも含まれていれば両方を読んで検査する。
version_source_requested() {
  local file normalized
  for file in "$@"; do
    normalized="${file#./}"
    [[ $normalized == "$SHIM_DEFS_FILE" || $normalized == "$LINTER_WORKFLOW_FILE" ]] && return 0
  done
  return 1
}

main() {
  local file
  if [[ $# -gt 0 ]]; then
    for file in "$@"; do
      check_file "$file"
    done
    version_source_requested "$@" && check_markdownlint_version_source
  else
    check_markdownlint_version_source
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
