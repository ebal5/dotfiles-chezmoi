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
- `[[ ]]` 構文を使用（`[ ]` より安全）
- 変数は `"$variable"` で囲む
- 数値検証は正規表現パターンマッチングを使用
