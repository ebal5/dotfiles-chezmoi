# My Dotfiles Managemen using Chezmoi

Chezmoi を利用して作成した dotfiles。
動作確認は今のところ Ubuntu のみ。
Bash と Zsh に対応。

## installation

### Ubuntu

前提:

- cURL, Git がインストール済み

```bash
# 一時的に使うchezmoiをインストールする
sh -c "$(curl -fsLS get.chezmoi.io)"
# このリポジトリを所定ディレクトリにクローンし適用
${HOME}/bin/chezmoi init https://github.com/ebal5/dotfiles-chezmoi.git
${HOME}/bin/chezmoi apply
# 初期スクリプトを起動する
${HOME}/once_setup_ubuntu.sh
# https -> sshへオリジンを変更する（SSHキーによるpush/pullを可能にする）
# cdの戻りを考えなくていいようにサブシェル
(
  ${HOME}/bin/chezmoi cd
  git remote set-url origin git@github.com:ebal5/dotfiles-chezmoi.git
)
# 初期に使用したchezmoiを削除しNixでインストールしたものを利用するようにする
rm ~/bin/chezmoi
```

## install 後の作業

`~/.config/local/` にマシン固有の設定ファイルを作成する。

### Git ユーザー設定

`~/.config/local/git_user_config` に Git 用のユーザー設定を記述する。

例: 基本のユーザー設定と、特定ディレクトリ配下の Git リポジトリのみで利用する設定を読み込む

```gitconfig
[user]
  name = USERNAME_OF_GITHUB
  email = EMAIL_ADDRESS@GITHUB

[includeIf "gitdir:~/Projects/SOME_COMPANY/"]
  path = PATH_OF_ONLY_SOMECOMPANY_CONFIG_FILE
```

### シェル用ローカル設定

マシン固有のシェル設定を以下のファイルに記述する。ファイルが存在する場合のみ自動的に読み込まれる。

| ファイル | タイミング | 用途 |
| ------- | --------- | ---- |
| `~/.config/local/profile.local` | ログイン時（1回） | 環境変数、PATH追加など |
| `~/.config/local/shellrc.local` | インタラクティブシェル起動時 | エイリアス、関数など |

例: GPU環境向けの設定

```sh
# ~/.config/local/profile.local
export CUDA_HOME="/usr/local/cuda"
export PATH="$CUDA_HOME/bin:$PATH"
export LD_LIBRARY_PATH="$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}"
```

### ssh鍵によるコミット署名設定

以下のコマンドでssh鍵によるGitコミットの署名を設定可能。
リポジトリごとに署名鍵を変更する場合は最後のコマンドをローカルとして各リポジトリで行うなどの工夫が必要。

```sh
git config gpg.format ssh
git config commit.gpgsign true
git config user.signingkey "$(ssh-add -L | grep 'SOME_CONDITION')"
```

### ユーザーレベルGitignore設定

このdotfilesは `~/.config/git/ignore` にユーザーレベルのgitignoreファイルを設定します。
このファイルは全てのGitリポジトリで自動的に適用され、以下のような開発環境固有のファイルを無視します：

- **Claude Code**: ローカル設定ファイル、キャッシュ、ログ
- **開発ツール**: Mise/RTX設定、IDE固有ファイル、エディタ一時ファイル
- **OS固有ファイル**: macOS、Windows、Linux生成ファイル
- **セキュリティ**: 環境変数ファイル、SSHキー、APIトークン
- **ビルド・キャッシュ**: 各言語のビルド成果物、パッケージマネージャーキャッシュ
- **コンテナ**: Docker Compose overrides、Vagrantファイル

プロジェクト固有のファイルを無視する場合は、各プロジェクトの `.gitignore` ファイルを使用してください。

## 設定内容

- パッケージ管理ツールを利用したセットアップ
- Bash / Zsh 対応（共通エイリアス、個別設定ファイル）
- SSH キーの共有（Bitwarden 利用）
  - <https://github.com/joaojacome/bitwarden-ssh-agent> の`6237a3604`を利用
  - 使用する場合、利用者各個人で内容確認推奨
- [Nix](https://nixos.org/) による開発ツール管理
  - CLIツール・開発コマンドを`flake.nix`で統合管理（約30パッケージ）
  - 主要ツール: git, fzf, ripgrep, fd, bat, starship, delta, lsd, mcfly, zoxide, xh, uv, bun, prek, actionlint など
  - 全パッケージ一覧は[flake.nix](flake.nix)を参照
  - システム環境の再現性を向上
  - パッケージ追加後の更新: `nix profile upgrade .` または `nix profile add .`
- [Starship](https://starship.rs/ja-jp/)
- [mise (alt asdf)](https://github.com/jdx/mise)（言語ランタイム管理: Node.js、Python）
- [uv](https://docs.astral.sh/uv/)（Pythonパッケージ管理・uvxによるツール実行）
- Git config
  - diff として delta を利用
  - 便利エイリアスを登録（よく使うコマンドの短縮など）
- 作成したスクリプトの共有
- [fzfユーティリティ](FZF_UTILS.md)（Docker、Git、ファイル検索、プロセス管理等のfzf連携コマンド）

### Zsh 固有の設定

- 履歴設定（重複除去、共有履歴など）
- オートコンプリーション
- 各種ツールとの統合（mise、starship、mcfly など）

[chezmoi's doc](https://www.chezmoi.io)

### Starship の主な設定内容

- プロンプトは 2 行に分け、1 行目を情報表示に利用する
- 実行結果末尾に改行がない場合付与する
- 設定したモジュールに関して、カッコ（"[" "]"）で囲い表示
- AWS の日本リージョンに関しては短縮表記を利用
- 実行に 5 秒以上かかったコマンドはかかった秒数を表示
- カレントディレクトリは直近 2 つのディレクトリのみ表示
- Git:ブランチを表示（`main`および`master`の場合は表示しない）
- Git:ワークツリーの追加行数・削除行数を表示
- Git:リポジトリの状態を表示（`!`: 差分あり、など）
- メモリ使用率が50%以上で表示
- Azure サブスクリプション、Terraform ワークスペースを表示
- コンテナ名を表示
- 2 行目プロンプトに時刻を表示

### 主なシェル用エイリアス（Bash / Zsh 共通）

| エイリアス | 展開 | 備考 |
| --- | --- | --- |
| `l` | `ls` | ディレクトリ配下の一覧 |
| `ll` | `ls -alF` | リスト表示 |
| `sl` | `ls` | タイポ対策 |
| `cd..` | `cd ..` | タイポ対策 |
| `..` | `cd ..` | |
| `...` | `cd ../../` | |
| `.2` | `cd ../../` | |
| `.3` | `cd ../../../` | |
| `cg` | `cd $(git rev-parse --show-toplevel)` | Gitリポジトリのトップにcdする |
| `gs` | `git status` | タイポ対策 |
| `tf` | `terraform` | |
| `g` | `git` | |
| `d` | `docker` | |
| `dc` | `docker compose` | |
| `ddu` | `docker compose down && docker compose up -d` | |
| `dup` | `docker compose up -d` | Docker起動 |
| `ddw` | `docker compose down` | Docker停止 |
| `dps` | `docker compose ps` | Docker状態表示 |
| `ruff` | `uvx ruff` | uvx経由のPython linter |
| `mypy` | `uvx mypy` | uvx経由の型チェック |
| `pre-commit` | `prek` | prek（Nix管理）へのエイリアス |

上記は主要なエイリアスの抜粋です。bunxツール群（biome, ccusage等）、fzfユーティリティ（[FZF_UTILS.md](FZF_UTILS.md)参照）、便利関数（stmp, mkcd, psg等）を含む全一覧は[dot_config/sh-like-aliases](dot_config/sh-like-aliases)を参照してください。

### 主な Git コマンドのエイリアス

| エイリアス | 展開 | 備考 |
| --- | --- | --- |
| `a` | `add` | ワークツリーのファイルをインデックスに登録する |
| `au` | `add -u` | インデックスに登録されているファイルに差分があれば登録する |
| `br` | `branch` | ブランチ |
| `c` | `commit` | コミット |
| `cam` | `commit --amend -m` | メッセージを記載してamend |
| `caum` | `commit --amend -am` | 更新ファイルを追加しメッセージを記載してamend |
| `cmm` | `commit -m` | メッセージを記載してcommit |
| `cum` | `commit -am` | 更新ファイルを追加しメッセージを記載してcommit |
| `co` | `checkout` | チェックアウト |
| `dns` | `diff --name-status` | 差分種類のみ確認 |
| `fsw` | `!git for-each-ref --format '%(refname:short)' refs/heads \| fzf \| xargs git switch` | fzfを利用してswitch |
| `fsn` | `!git branch --no-merged origin/master --format='%(refname:short)' \| fzf \| xargs git switch` | マージされていないブランチにfzfを利用してswitch |
| `fw` | `!git for-each-ref --format '%(refname:short)' refs/heads \| fzf \| xargs git switch` | fwと同じ |
| `graph` | `log --graph --date=short --decorate=short --pretty=format:'%Cgreen%h %Creset%cd %Cblue%cn %Cred%d %Creset%s'` | コミットグラフを表示 |
| `l` | `log` | ログ |
| `l5` | `log --first-parent -n 5` | 5個前までのログ |
| `l10` | `log --first-parent -n 10` | 10個前までのログ |
| `l15` | `log --first-parent -n 15` | 15個前までのログ |
| `pl` | `pull` | プル |
| `poh` | `push origin HEAD` | originに現在のブランチをpush |
| `rst` | `reset` | リセット |
| `rh` | `reset --hard` | ワークツリーとインデックスを指定の状態に変更（未指定:HEAD） |
| `rmc` | `rm --cached` | インデックスへの登録のみ削除 |
| `s` | `status` | ステータスを表示 |
| `ss` | `status` | ステータスを表示 |
| `sw` | `switch` | ブランチを変更 |
| `top` | `rev-parse --show-toplevel` | Gitリポジトリのトップレベルパスを表示 |
| `wip` | `stash` | 一時領域関連 |
| `wipl` | `stash list` | 一時領域のリストを表示 |
| `wips` | `stash push` | 更新内容を一時領域に保存 |
| `wipp` | `stash pop` | 一時領域から更新を取得 |

上記は主要なエイリアスの抜粋です。push/fetch系（ps, psf, psu, f, fa）、diff系（d, dc, ds）、ブランチ管理（bd, bdd, current, upstream）、便利コマンド（acp, sync, save, unstage, uncommit等）を含む全一覧は[dot_gitconfig](dot_gitconfig)を参照してください。

## Claude Code 設定

このdotfilesには[Claude Code](https://claude.ai/code)のグローバル設定が含まれています。
`chezmoi apply`により`~/.claude/`に展開されます。

### 含まれる設定

| ファイル | 内容 |
| --- | --- |
| `settings.json` | グローバル設定（権限、フック、モデル、プラグイン） |
| `.mcp.json` | グローバルMCPサーバー設定 |
| `CLAUDE.md` | 全プロジェクト共通の指示 |
| `commands/` | カスタムスラッシュコマンド |
| `stop-hook-git-check.sh` | 停止時のGit状態チェックフック |

### カスタムスラッシュコマンド

| コマンド | 説明 |
| --- | --- |
| `/project:init` | プロジェクトのClaude Code初期設定 |
| `/mcp:aws` | AWS MCPサーバーをプロジェクトに追加 |
| `/mcp:terraform` | Terraform MCPサーバーをプロジェクトに追加 |
| `/docker:compose-up` | Docker Composeでサービス起動 |
| `/git:sync-from-origin` | 現在のブランチをoriginに強制同期 |
| `/python:lint` | ruffでPythonコードをlint/format |
| `/python:test` | pytestでテスト実行 |
| `/python:security` | banditでセキュリティスキャン |
| `/aws:enable-readonly` | AWS読み取り系コマンドの許可を追加 |
| `/chezmoi:verify-sync` | chezmoiソースとデプロイ先の同期検証 |
| `/lint:all` | 全ファイルタイプの統合lint/formatチェック |

### グローバルMCPサーバー

認証不要で全プロジェクトで利用可能なMCPサーバー:

| サーバー | 用途 |
| --- | --- |
| context7 | ライブラリドキュメント検索 |
| sequential-thinking | 複雑な問題の段階的思考支援 |
| serena | IDEアシスタント機能 |

### スキルジェネレーター

[Anthropic公式のスキルジェネレータープラグイン](https://github.com/anthropics/skills)が有効化されています。

#### 使い方

1. Claude Codeで「〇〇のスキルを作成して」と依頼
2. スキルジェネレーターが自動的にスキルファイルを生成
3. 生成されたスキルは`.claude/skills/`に保存される

#### 同梱スキル

| スキル | 説明 |
| --- | --- |
| `grill-me` | プランや設計を徹底的にヒアリング |
| `handover` | セッション終了時の引き継ぎドキュメント作成 |
| `markdown-check` | Markdownドキュメントの整合性・リンク切れ検証 |
| `uv-script` | uvシバン付きスタンドアロンPythonスクリプト作成 |

#### スキルとは

スキルはClaude Codeが特定のタスクを実行するための再利用可能な指示セットです。
スラッシュコマンドとは異なり、Claudeが文脈に応じて自動的に使用します。

```text
.claude/skills/
└── my-skill/
    └── SKILL.md    # スキル定義ファイル
```

#### スキルファイルの形式

```markdown
---
name: skill-name
description: スキルの説明（Claudeが使用判断に利用）
allowed-tools: Edit, Bash(npm:*)
---

# スキルの指示

ここにClaude向けの詳細な指示を記述。
```

### 権限設定

デフォルトで許可されている操作（確認なし）:

- Git操作: fetch, checkout, add, commit, branch, reset
- GitHub CLI: PR/Issue閲覧、ステータス確認
- Web検索、ドキュメント取得

確認が必要な操作（askリスト）:

- `git push`, `git merge`
- `gh issue create`, `gh pr create`, `gh label create`

### 設定のカスタマイズ

プロジェクト固有の設定は以下のファイルで上書き可能:

- `.claude/settings.json` - プロジェクト共有設定
- `.claude/settings.local.json` - ローカル専用設定（gitignore推奨）
- `.claude/.mcp.json` - ローカル専用MCPサーバー（gitignore推奨）

## チェック内容

### shfmt

シェルスクリプトファイルは更新時にshfmtによってチェックされている。

### markdownlint-cli2

フォルダ内の Markdown ファイルは更新時にmarkdownlint-cli2によってチェックされている。

NOTE: markdownlintによるチェックとの違いは要検証

## その他

- マイグレーション履歴は [MIGRATION.md](MIGRATION.md) を参照
- 機能拡張や問題報告は Issues へ
