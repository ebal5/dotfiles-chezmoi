# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリで作業する際のガイダンスを提供します。

## リポジトリ概要

Ubuntu環境向けのChezmoiで管理された個人用dotfilesリポジトリです。シェル環境、開発ツール、設定ファイルのセットアップを自動化します。

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
