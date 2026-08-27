---
paths: executable_*, dot_scripts/**, **/*.sh, **/*.bash
description: シェルスクリプト開発ガイドライン
---

# シェルスクリプト開発ガイドライン

新しいシェルスクリプトを作成する際は、以下の標準パターンに従ってください。

## 必須要素

### 1. Shebangとset

```bash
#!/usr/bin/env bash
set -euo pipefail
```

### 2. 依存関係チェック関数

```bash
check_dependencies() {
  local deps=("$@")
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      echo "Error: $dep is required but not installed." >&2
      exit 1
    fi
  done
}
```

### 3. クリーンアップ関数

```bash
# 一時ファイルがある場合
temp_files=()
cleanup() {
  for file in "${temp_files[@]}"; do
    [[ -n "$file" && -f "$file" ]] && rm -f "$file" 2>/dev/null || true
  done
}
trap cleanup EXIT
```

### 4. 引数検証

```bash
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <argument>" >&2
  exit 1
fi
```

## セキュリティ要件

- 一時ファイルは `chmod 600` で作成
- ユーザー入力の検証を実装
- エラーメッセージは標準エラー出力（`>&2`）に出力

## ベストプラクティス

- 関数とスクリプトの先頭で依存関係をチェック
- 数値検証は正規表現パターンマッチングを使用

`[[ ]]`の使用（SC2292）や変数のクォート（SC2086）は`.shellcheckrc`の`enable=all`で
shellcheckが検出するため、ここには書かない。

## `.tmpl`ファイルの扱い

Chezmoiテンプレート（`.tmpl`）はGoテンプレート構文 `{{ }}` を含むため、
shfmtとshellcheckがパースできない。したがって**`.tmpl`にシェルコードを置かない**。

条件分岐だけを`.tmpl`のランチャーに残し、本体は`scripts/`配下の素の`.sh`に置く。
素の`.sh`は既存のゲート（shfmt / shellcheck / prek / CI / PostToolUseフック）が
そのまま担保する。詳細は[CLAUDE.md](../../CLAUDE.md)の
「`.tmpl`ランチャーと本体スクリプトの分離」を参照。

ランチャーを書くときの注意:

- 先頭に条件分岐を置き、その後にshebangが続くならtrim marker（`-}}`）が必須。
  空行を挟んでも同じ（`check-repo-conventions.sh`が検出する）
- `run_once_`/`run_onchange_`のランチャーには
  `{{ include "<本体パス>" | sha256sum }}`をコメントで埋める。
  埋めないと本体を編集しても再実行されない
- `#!/bin/sh`で書く本体には先頭に`# shellcheck shell=sh`を置く

## 編集後のlint実行

PostToolUseフック（`.claude/hooks/lint-edited-file.sh`）が編集後に
shfmtでフォーマットし、shellcheckの指摘があれば返すため、手動実行は不要。
`.tmpl`はスキップされる（シェルコードを置かないため問題にならない）。

全ファイルに対して実行する場合は `/lint:all` コマンドを使用。
