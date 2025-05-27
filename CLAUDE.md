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

### ファイル管理とIgnore設定

- `.chezmoiignore` - ホームディレクトリに適用しないファイルを指定
- 新しいドキュメントファイルや開発用ファイルを追加した場合は、必要に応じて`.chezmoiignore`に追記

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

## シェルスクリプト開発ガイドライン

新しいシェルスクリプトを作成する際は、以下の標準パターンに従ってください:

### 必須要素

1. **Shebangとset**

   ```bash
   #!/usr/bin/env bash
   set -euo pipefail
   ```

2. **依存関係チェック関数**

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

3. **クリーンアップ関数**

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

4. **引数検証**

   ```bash
   if [[ $# -ne 1 ]]; then
     echo "Usage: $0 <argument>" >&2
     exit 1
   fi
   ```

### セキュリティ要件

- 一時ファイルは `chmod 600` で作成
- ユーザー入力の検証を実装
- エラーメッセージは標準エラー出力（`>&2`）に出力

### ベストプラクティス

- 関数とスクリプトの先頭で依存関係をチェック
- `[[ ]]` 構文を使用（`[ ]` より安全）
- 変数は `"$variable"` で囲む
- 数値検証は正規表現パターンマッチングを使用

## セキュリティ検証済みコンポーネント

以下のコンポーネントは事前にセキュリティ検証が完了しており、一定期間はセキュリティレビューの対象外とします:

### Bitwarden SSH Agent

- **リポジトリ**: <https://github.com/joaojacome/bitwarden-ssh-agent.git>
- **コミットハッシュ**: `6237a3604d640533ad4123d23e23ddfd4e3666d2`
- **検証日**: 2025-05-27
- **検証者**: ebal5
- **ステータス**: ✅ 検証済み・安全
- **備考**: 動作・コードを事前検証済み。問題ないことを確認

## ドキュメント作成ガイドライン

### Markdownスタイル

Markdownlintルールに準拠したドキュメント作成を推奨:

- **MD031**: フェンスコードブロック（```）の前後には空行を入れる
- **コードブロックの書式**:

  ```markdown
  テキスト
  
  ```bash
  コード内容
  ```
  
  続きのテキスト
  ```

- **見出し**: 一貫したレベル構造を維持
- **リスト**: インデントと記号の統一

### ドキュメント構成

- **概要**: プロジェクト/機能の簡潔な説明
- **使用方法**: 具体的なコマンド例と説明
- **設定**: 設定ファイルの場所と重要なオプション
- **トラブルシューティング**: よくある問題と解決方法
