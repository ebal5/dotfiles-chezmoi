---
paths: "**/*.sh", "**/*.bash", "**/*.md", .github/**
description: リントと品質チェックのコマンドとCI設定
---

# リントと品質チェック

## コマンド

- `shfmt -i 2 -ci -w .` - シェルスクリプトを2スペースインデントでフォーマット
- `shellcheck $(shfmt -f .)` - シェルスクリプトの問題をチェック
- `markdownlint-cli2 "**/*.md"` - Markdownファイルをリント（`.`だとトップレベルのみ）

編集単位のlintはPostToolUseフック（`.claude/hooks/lint-edited-file.sh`）が自動実行するため、
上記は全体を一括チェックしたいときに使う。

## GitHub Actions 自動実行

GitHub Actionsが以下を自動実行:

- シェルスクリプト用shfmtフォーマット
- シェルスクリプト解析用shellcheck
- Markdownファイル用markdownlint-cli2

## 統合 lint コマンド

すべてのlintを一括実行するには `/lint:all` コマンドを使用。
