---
paths: dot_*, .chezmoiignore, .chezmoi*
description: Chezmoi設定管理ガイドライン
---

# Chezmoi管理

## 基本コマンド

- `chezmoi apply` - 設定変更をホームディレクトリに適用
- `chezmoi edit <file>` - 設定ファイルを編集
- `chezmoi diff` - ソースとターゲット状態の差分を表示
- `chezmoi cd` - chezmoiソースディレクトリに移動

## ファイル管理とIgnore設定

- `.chezmoiignore` - ホームディレクトリに適用しないファイルを指定
- 新しいドキュメントファイルや開発用ファイルを追加した場合は、必要に応じて`.chezmoiignore`に追記
