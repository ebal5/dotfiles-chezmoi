# fzf便利ユーティリティ

このドキュメントでは、dotfilesに追加されたfzfベースの便利コマンドについて説明します。

## 概要

`dot_scripts/executable_fzf_utils.sh`に9つの便利なfzf機能が実装されており、各機能は短縮エイリアスでアクセスできます。

## 利用可能なコマンド

### 1. Docker Container Selector (`fzdc`)

Dockerコンテナをインタラクティブに選択し、操作します。

```bash
fzdc
```

**機能:**
- 全コンテナの一覧表示
- リッチなプレビュー（ステータス、IP、ポート、環境変数など）
- キーバインド:
  - `Enter`: bashまたはshでコンテナに接続
  - `Ctrl-L`: ログ表示
  - `Ctrl-S`: コンテナ開始
  - `Ctrl-K`: コンテナ停止

### 2. Git Branch Selector (`fzgb`)

Gitブランチを選択してチェックアウトします。

```bash
fzgb
```

**機能:**
- ローカル・リモートブランチの一覧
- ブランチのコミット履歴プレビュー
- 選択したブランチに自動チェックアウト

### 3. Git Log Explorer (`fzgl`)

Gitコミット履歴をインタラクティブに閲覧します。

```bash
fzgl
```

**機能:**
- カラー付きコミットグラフ
- コミット詳細のプレビュー
- キーバインド:
  - `Enter`: コミット詳細表示
  - `Ctrl-C`: 選択したコミットにチェックアウト

### 4. File Search (`fzff`)

プロジェクト内のファイルを検索して編集します。

```bash
fzff
```

**機能:**
- ripgrep/fd/findを自動検出して使用
- ファイル内容のプレビュー（batが利用可能な場合は色付き）
- 選択したファイルをエディタで開く

### 5. Process Killer (`fzpk`)

実行中のプロセスを選択して終了します。

```bash
fzpk
```

**機能:**
- 全プロセスの一覧表示
- マルチ選択対応（Tabキー）
- 選択したプロセスを`kill`で終了

### 6. SSH Host Selector (`fzsh`)

SSH設定ファイルからホストを選択して接続します。

```bash
fzsh
```

**機能:**
- `~/.ssh/config`からホスト一覧を取得
- ホスト設定のプレビュー
- 選択したホストに自動接続

### 7. Git Diff Viewer (`fzgd`)

変更されたファイルの差分を表示します。

```bash
fzgd
```

**機能:**
- 変更されたファイルの一覧
- ファイルごとの差分プレビュー
- 選択したファイルの詳細差分をlessで表示

### 8. Docker Image Manager (`fzdi`)

Dockerイメージを管理します。

```bash
fzdi
```

**機能:**
- Dockerイメージ一覧（タグ、サイズ、作成日付）
- イメージ詳細のプレビュー
- キーバインド:
  - `Enter`: イメージ詳細表示
  - `Ctrl-R`: イメージからコンテナ実行
  - `Ctrl-D`: イメージ削除

### 9. Recent Directory Navigator (`fzcd`)

最近使用したディレクトリに移動します。

```bash
fzcd
```

**機能:**
- ディレクトリ履歴の管理
- ディレクトリ内容のプレビュー
- 選択したディレクトリに移動

## 依存関係

各コマンドは必要な依存関係を自動チェックします：

- **基本**: `fzf` (全コマンド共通)
- **Docker関連**: `docker`
- **Git関連**: `git`
- **推奨ツール**: `rg` (ripgrep), `fd`, `bat`

## インストール

Chezmoiを使用している場合、以下のコマンドで設定を適用します：

```bash
chezmoi apply
```

その後、新しいシェルセッションを開始するか、設定を再読み込みします：

```bash
source ~/.bashrc
# または
source ~/.zshrc
```

## カスタマイズ

`dot_scripts/executable_fzf_utils.sh`を編集することで、各コマンドの動作をカスタマイズできます。新しい機能を追加する場合は、以下の手順を参考にしてください：

1. スクリプトに新しい関数を追加
2. `case`文に新しいコマンドを登録
3. `dot_config/sh-like-aliases`に対応するエイリアスを追加
4. このドキュメントに使用方法を記載

## トラブルシューティング

### コマンドが見つからない

```bash
# パスを確認
which fzdc

# スクリプトの実行権限を確認
ls -la ~/.scripts/fzf_utils.sh

# 権限がない場合
chmod +x ~/.scripts/fzf_utils.sh
```

### fzfが利用できない

```bash
# Ubuntu/Debian
sudo apt install fzf

# WSL2の場合は、Windowsのfzfも利用可能
```

### プレビューが表示されない

一部のプレビュー機能では追加ツールが必要です：

```bash
# bat (syntax highlighting)
sudo apt install bat

# ripgrep (fast file search)
sudo apt install ripgrep

# fd (fast file find)
sudo apt install fd-find
```