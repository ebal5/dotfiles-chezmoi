---
paths: dot_config/sh-like-aliases, **/*fzf*
description: fzfユーティリティコマンド
---

# fzfユーティリティ

このリポジトリには、fzfベースの便利なユーティリティコマンドが含まれています。

## 主要なfzfコマンド

- `fzdc` - Dockerコンテナ選択・操作
- `fzds` - Dockerコンテナ選択（名前のみ出力）
- `fzgb` - Git ブランチ選択・チェックアウト
- `fzgl` - Git ログ閲覧
- `fzff` - ファイル検索・編集
- `fzpk` - プロセス選択・終了
- `fzsh` - SSH ホスト選択・接続
- `fzgd` - Git 差分表示
- `fzdi` - Docker イメージ管理
- `fzcd` - 最近のディレクトリ移動

## 使用方法

すべてのコマンドはエイリアスとして `dot_config/sh-like-aliases` で定義されており、シェル起動時に自動的に利用可能になります。

詳細な使用方法は `FZF_UTILS.md` を参照してください。

## 依存関係

- `fzf` (必須)
- `docker` (Docker関連コマンド用)
- `git` (Git関連コマンド用)
- `ripgrep`, `fd`, `bat` (推奨・性能向上)
