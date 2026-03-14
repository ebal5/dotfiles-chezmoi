---
description: 全ファイルタイプの統合lint/formatチェックを実行します
allowed-tools: Bash(shfmt:*), Bash(shellcheck:*), Bash(markdownlint-cli2:*), Bash(ruff:*), Bash(uv run ruff:*)
---

プロジェクト内のすべてのコードに対してlint/formatチェックを実行してください。

## 実行手順

### 1. シェルスクリプト

1. `shfmt -i 2 -ci -w .` でフォーマット
2. `shfmt -f .` で対象ファイル一覧を取得し、出力が空でなければ `shellcheck $(shfmt -f .)` で静的解析（対象ファイルが0件の場合はスキップ）

### 2. Markdownファイル

1. `markdownlint-cli2 .` でMarkdownリントを実行

### 3. Pythonファイル（存在する場合）

`pyproject.toml` または `ruff.toml` が存在する場合のみ:

1. `ruff check --fix .` でlintエラーを自動修正
2. `ruff format .` でフォーマット

## 報告

各ステップの結果を以下の形式で報告:

- 各リンターの実行結果（pass/fail）
- 自動修正された箇所の一覧
- 残存するエラーがあれば修正方法を提案

## 注意事項

- 各ツールが未インストールの場合はスキップして次に進む
- ruff は check と format を必ずセットで実行する
