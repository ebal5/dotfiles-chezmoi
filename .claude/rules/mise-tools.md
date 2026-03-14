---
paths: "**/*mise*", .tool-versions, executable_once_setup_*
description: mise（ツールバージョン管理）
---

# mise（ツールバージョン管理）

## 概要

mise（旧rtx）はプロジェクトごとのツールバージョン管理ツール。
asdfの高速なRust実装として、Node.js、Python等の言語ランタイムを管理。

## 基本コマンド

- `mise install` - 設定ファイルに基づいてツールをインストール
- `mise use <tool>@<version>` - ツールのバージョンを指定して使用
- `mise ls` - インストール済みツールを一覧表示
- `mise current` - 現在のディレクトリで有効なツールバージョンを表示

## 設定ファイル

- `.mise.toml` または `mise.toml` - miseネイティブ設定
- `.tool-versions` - asdf互換の設定ファイル
