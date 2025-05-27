# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリで作業する際のガイダンスを提供します。

## リポジトリ概要

Ubuntu環境向けのChezmoiで管理された個人用dotfilesリポジトリです。シェル環境、開発ツール、設定ファイルのセットアップを自動化します。

## 主要コマンド

### Chezmoi管理

- `chezmoi apply` - 設定変更をホームディレクトリに適用
- `chezmoi edit <file>` - 設定ファイルを編集
- `chezmoi diff` - ソースとターゲット状態の差分を表示
- `chezmoi cd` - chezmoiソースディレクトリに移動

### リントと品質チェック
- `shfmt -i 2 -ci -w .` - シェルスクリプトを2スペースインデントでフォーマット
- `shellcheck $(shfmt -f .)` - シェルスクリプトの問題をチェック
- `markdownlint-cli2 .` - Markdownファイルをリント

### Git操作
dot_gitconfigで定義された豊富なGitエイリアスを含む:
- `g s` / `gs` - Git status
- `g c` / `g cmm` - メッセージ付きGit commit
- `g poh` - origin HEADにpush
- `g graph` - コミットグラフを表示
- `g fsw` - fzfを使用したファジーブランチ切り替え

## アーキテクチャ

### 設定構造
- `dot_*` ファイル: ホームディレクトリにシンボリックリンクされる直接的なdotfiles
- `dot_config/`: .configディレクトリ用の設定ファイル
- `dot_scripts/`: カスタムスクリプトディレクトリ
- `executable_once_*`: 異なるプラットフォーム用の一回限りのセットアップスクリプト

### 主要コンポーネント
- **シェル環境**: Starshipプロンプト付きBash、豊富なエイリアス
- **ツール管理**: バージョン管理用のmise（旧rtx）
- **Git設定**: Deltaディフビューア、包括的なエイリアス
- **開発ツール**: mise経由での各種開発ツールの統合セットアップ

### エイリアスシステム
リポジトリは2層のエイリアスを定義:
1. `dot_config/sh-like-aliases`のBashエイリアス（ナビゲーション、docker、gitショートカット）
2. `dot_gitconfig`のGitエイリアス（gitコマンドショートカット）

## プラットフォームサポート
- 主要: Ubuntu/WSL2
- セットアップスクリプト: Ubuntu（`executable_once_setup_ubuntu.sh.tmpl`）
- Windows サポート: PowerShellセットアップスクリプト利用可能

## 品質保証
GitHub Actionsが自動実行:
- シェルスクリプト用shfmtフォーマット
- シェルスクリプト解析用shellcheck
- Markdownファイル用markdownlint-cli2
- セキュリティスキャン用detect-secrets