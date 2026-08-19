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

### pre-commitフックの導入（このリポジトリを編集する場合）

```sh
prek install
```

共有設定にマシン固有・組織固有の値が混入していないかを commit 時に検査する
（[後述](#共有設定へのマシン固有値の混入防止)）。

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
  - CLIツール・開発コマンドを`flake.nix`で統合管理（約40パッケージ）
  - 主要ツール: git, fzf, ripgrep, fd, bat, starship, delta, lsd, mcfly, zoxide, xh, uv, bun, prek, actionlint など
  - TUIツール: zellij, herdr（エージェント多重化）, oxker, ov, glow
  - 全パッケージ一覧は[flake.nix](flake.nix)を参照
  - `flake.lock`をバージョン管理下に置き、マシン間でnixpkgsリビジョンを固定する
  - パッケージ追加後の更新: `nix profile upgrade --all`（nix 2.32以降。`nix profile upgrade .`は非対応）
  - ツールのバージョン更新: `git pull`で`flake.lock`を取得してから`nix profile upgrade --all`
  - `flake.lock`自体の更新は週次のGitHub Actionsが自動PR化する（後述）
- [Starship](https://starship.rs/ja-jp/)
- [mise (alt asdf)](https://github.com/jdx/mise)（プロジェクトごとにバージョン固定が必要なツールの管理: Node.js、Python等）
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
| `c2f` | `$HOME/.scripts/clip2file` | クリップボードを一時ファイルへ保存しパスをコピー |

上記は主要なエイリアスの抜粋です。pnpm shimツール群（biome, ccusage等）、fzfユーティリティ（[FZF_UTILS.md](FZF_UTILS.md)参照）、便利関数（stmp, mkcd, psg等）を含む全一覧は[dot_config/sh-like-aliases](dot_config/sh-like-aliases)を参照してください。

### クリップボードを一時ファイルへ退避（clip2file）

AIエージェントに渡すテキストなどを、クリップボードから一時ファイルへ保存し、
その保存先パスをクリップボードへ入れ直す（`~/.scripts/clip2file`、エイリアスは`c2f`）。

```bash
c2f              # /tmp/clip/clip-20260818-231900-Ab12Cd.txt へ保存しパスをコピー
c2f -e md        # 拡張子を md にする
c2f -n note.md   # ファイル名を固定する
c2f -d ~/tmp     # 保存先ディレクトリを変える（既定は $CLIP2FILE_DIR、未設定なら /tmp/clip）
```

テキストが空のときだけ画像を探し、画像があればPNGとして保存する。
WSLでは`win32yank.exe`（テキスト）と`powershell.exe`（画像）、
それ以外のLinuxでは`xclip`、無ければ`xsel`（テキストのみ）を使う。
保存先パスは標準出力にも出るため`file=$(c2f)`のように受け取れる。

### herdrプラグイン

herdrのプラグインはサンドボックス無しで自分の権限のまま動く任意コードで、
herdr側には署名検証もチェックサムも`plugin update`も無い
（マーケットプレイスもGitHubトピックの自動収集で審査は無い）。
そのため`herdr plugin install`は使わない。あれはプラグイン側の`[[build]]`を
無条件に実行し、checkoutをherdr管理下に置いて再インストールで差し替えるため、
「監査した木」と「動いている木」が一致しない。

代わりに[dot_config/herdr-plugins](dot_config/herdr-plugins)へ
**完全な40桁commit SHA**でピン止めし、
`run_onchange_after_install_herdr_plugins.sh.tmpl`が次を行う。

1. `~/.local/share/herdr-plugins/<owner>_<repo>`へ`git fetch --depth 1 <SHA>`で取得
2. checkoutのHEADがピンと一致するか照合（不一致なら登録しない）
3. 定義ファイルに書いたビルドコマンドだけを実行（herdr側の`[[build]]`は走らない）
4. `herdr plugin link`で登録

結果として、**何が実行されるかは定義ファイルの1行だけで決まり、
バージョン更新はPRのdiffに現れる**。

| 状況 | 挙動 |
| --- | --- |
| 定義ファイル未変更 | 何もしない（`run_onchange_`） |
| SHA変更 | `git clean -xdff`してから再取得・再ビルド |
| ビルド失敗 | linkせずに次のプラグインへ進む |
| 定義から削除 | `herdr plugin unlink`してcheckoutごと削除 |
| 手動でunlink済み | 次回applyで再link |
| herdr未導入 | 何もせず終了 |

導入済み:

| プラグイン | 用途 | 依存の扱い |
| --- | --- | --- |
| `jt.command-palette` | fzfによる全プラグインアクションの一覧・実行 | bash 2本のみ。fzf/jqはNix管理 |
| `tdi.worktree-setup` | worktree作成時のper-projectセットアップ実行 | npm依存はsmol-toml 1個。`npm ci --ignore-scripts` |

選定基準は2つ。lockfileを固定してビルドできること
（`npm install`しか用意がないものは入れない）と、
ツールチェーンをこのマシンに持ち込まないこと。
後者でRust製プラグインは見送っている（理由は定義ファイルのコメントに残してある）。

プラグインごとの設定は`~/.config/herdr/plugins/config/<plugin-id>/config.toml`に置く
（`herdr plugin config-dir <plugin-id>`で確認できる）。リポジトリ管理外。
キーバインドはherdrのマニフェストからは効かないため`~/.config/herdr/config.toml`に書く。

```toml
[[keys.command]]
key = "prefix+p"
type = "plugin_action"
command = "jt.command-palette.open"
description = "Command palette"
```

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

### フック

`settings.json`のSessionStart/SessionEndから`~/.scripts/`のスクリプトを呼び出す。

| スクリプト | 役割 |
| --- | --- |
| `tmux_claude_title.sh` | tmuxウィンドウタイトルの設定・復帰 |
| `herdr_agent_state.sh` | herdrへのエージェント状態通知（ラッパー） |

`herdr_agent_state.sh`は`~/.claude/hooks/herdr-agent-state.sh`への薄いラッパー。
委譲先はherdr管理（更新で上書きされる）なのでリポジトリには含めず、
存在すれば実行し、herdr外や未インストール時は何もせず終了する。
有効化はマシンごとに一度だけ`herdr integration install claude`を実行する。

herdrのインストーラは`bash '/home/<user>/.claude/hooks/herdr-agent-state.sh' session`
という絶対パスのフックを`settings.json`へ追記する。
`~/.claude/settings.json`は`dot_claude/settings.json.src`へのシンボリックリンクなので、
放置するとユーザー名込みの固定パスがリポジトリに入る。追記されていたら削除してよい
（ラッパーが同じ役割を果たす）。herdr側の重複検出はコマンド文字列の完全一致なので
ラッパー形式は認識されず、`herdr integration install`を実行するたび再追記される
（`herdr update`が内部で再実行するかは未確認）。両方残っても通知は冪等で害はない。

### カスタムスラッシュコマンド

| コマンド | 説明 |
| --- | --- |
| `/chezmoi:verify-sync` | chezmoiソースとデプロイ先の同期検証 |
| `/lint:all` | 全ファイルタイプの統合lint/formatチェック |

### グローバルMCPサーバー

認証不要で全プロジェクトで利用可能なMCPサーバー:

| サーバー | 用途 |
| --- | --- |
| context7 | ライブラリドキュメント検索 |
| serena | IDEアシスタント機能 |

### エージェントスキル

スキルはプラグインではなく、`run_once_after_install_agent_skills.sh.tmpl`が
`gh skill install`でユーザースコープ（`~/.claude/skills/`）へ導入する。
供給元は2つで、いずれもバージョンをピン留めしている。

| 供給元 | ピン | 導入するスキル |
| --- | --- | --- |
| [ebal5/agent-skills](https://github.com/ebal5/agent-skills) | タグ（`OWN_PIN`） | `install-sets/common.txt`の記載に従う |
| [anthropics/skills](https://github.com/anthropics/skills) | コミットSHA（`UPSTREAM_PIN`） | `skill-creator`, `mcp-builder`, `pdf`, `doc-coauthoring` |

自作スキルの一覧はピン先の`install-sets/common.txt`が唯一の情報源で、
このREADMEには複製しない。ピンを上げるとスクリプトの内容ハッシュが変わり、
次回の`chezmoi apply`で再実行されて新しい一覧が反映される。

`enabledPlugins`は空であり、プラグイン経由でスキルを導入してはいない。

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

### 共有設定へのマシン固有値の混入防止

`~/.claude/settings.json`と`~/.claude/.mcp.json`は`dot_claude/*.src`への
シンボリックリンクであり、Claude Code自身や外部ツール（herdr等）が直接書き込む。
このリポジトリはpublicなので、書き込まれた内容はそのまま公開されうる。
実際にauto modeが学習した業務プロジェクトの組織名・社内ドメイン・
ローカルパスが作業ツリーに書き込まれたことがある。

`.github/scripts/check-shared-settings.sh`がこれを検出する。

| 検出対象 | 例 |
| --- | --- |
| マシン固有の絶対パス | `/home/<user>/...`, `C:\Users\...` |
| 未知のGitHubオーナー | allowlist外の`github.com:<org>/<repo>` |
| 未知のホスト名 | 社内ドメインなど、allowlist外のホスト |
| ローカルdenylist該当語 | `~/.config/local/shared-settings-denylist`（任意） |

禁止語のリストをリポジトリに置くとそれ自体が流出になるため、判定はallowlist方式。
固有名詞を弾きたい場合のみ、マシンローカルの
`~/.config/local/shared-settings-denylist`（1行1パターン）に記述する。

実行経路は2つ:

- pre-commit（[prek](https://github.com/j178/prek)）: `prek install`で導入。`.pre-commit-config.yaml`を参照
- GitHub Actions: `shared-settings-guard.yaml`が該当ファイルの変更時に実行

正当な追加でフックが落ちる場合は、スクリプト冒頭の`ALLOWED_OWNERS`／
`ALLOWED_HOSTS`を更新する。

## チェック内容

### shfmt

シェルスクリプトファイルは更新時にshfmtによってチェックされている。

### markdownlint-cli2

フォルダ内の Markdown ファイルは更新時にmarkdownlint-cli2によってチェックされている。

NOTE: markdownlintによるチェックとの違いは要検証

## 定期アップデート

### flake.lock（Nix管理ツール）

`.github/workflows/flake-lock-update.yaml`が毎週月曜09:00 UTC（JST 18:00）に実行される。

| ステップ | 内容 |
| --- | --- |
| 更新 | `nix flake update`を実行し、差分がなければ何もせず終了 |
| コミット | `nix/flake-lock-update`ブランチに`flake.lock`をコミット |
| 再現性チェック | `nix build .#default`でビルド可否を検証 |
| PR | PRを作成（既存PRがあれば本文を更新してコメント追加） |

`GITHUB_TOKEN`が作成したPRはworkflowをトリガーしないため、この自動PRにはCIチェックが付かない。
そのため再現性チェックはワークフロー内で実施し、結果をPR本文に記載している。
ビルドが失敗した場合はワークフロー自体がfailするため、Actionsタブと通知で気付ける。

手動実行は`workflow_dispatch`（ActionsタブのRun workflow）から可能。

### mise管理ツール

mise設定（`~/.config/mise/config.toml`）はマシンローカルでリポジトリ管理外のため、
CIによる自動化対象ではない。手動で更新する。

```bash
mise upgrade
```

mise本体はNix・APTいずれの管理下にもなく、初回のみ`executable_once_setup_ubuntu.sh.tmpl`が
公式インストーラで`~/.local/bin/mise`へ導入する。以降の更新は手動で行う。

```bash
mise self-update
```

NOTE: Node.jsの更新にはリリース署名鍵の検証が必要。
`gpg: Can't check signature: No public key`で失敗する場合は
[nodejs/release-keys](https://github.com/nodejs/release-keys)から該当鍵をimportする。

## その他

- マイグレーション履歴は [MIGRATION.md](MIGRATION.md) を参照
- 機能拡張や問題報告は Issues へ
