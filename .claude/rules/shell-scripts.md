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
shfmtとshellcheckを直接かけることはできない。
`.sh.tmpl`については`.github/scripts/check-tmpl-shell.sh`が
テンプレートアクションを無害化した一時ファイルを作り、shellcheckにかける。
行数を保存するので、報告される行番号は元の`.tmpl`の行番号と一致する。

制限:

- **shfmtは対象外**。整形結果を一時ファイルから元の`.tmpl`へ書き戻す経路が
  ないため。インデント（2スペース）は手で揃えること
- `{{ else }}`を持つファイルは両方の枝が連結された状態で検査される
- テンプレートアクションは1行に収めること。複数行にまたがる形は検査できない
- shebangより前に置ける行アクションはtrim marker付き（`{{ ... -}}`）のみ。
  markerが無いとレンダリング後にshebangが1行目に来ない

`.sh.tmpl`以外の`.tmpl`（`.ps1.tmpl`、`.json.tmpl`等）は対象外。

## 編集後のlint実行

PostToolUseフック（`.claude/hooks/lint-edited-file.sh`）が編集後に
shfmtでフォーマットし、shellcheckの指摘があれば返すため、手動実行は不要。
`.sh.tmpl`は上記のチェッカー経由でshellcheckのみ実行する。

全ファイルに対して実行する場合は `/lint:all` コマンドを使用。
