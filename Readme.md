# My Dotfiles Managemen using Chezmoi

Chezmoi を利用して作成した dotfiles。
動作確認は今のところ Ubuntu のみ。

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
# 初期に使用したchezmoiを削除しmiseでインストールしたものを利用するようにする
rm ~/bin/chezmoi
```

## install 後の作業

`~/.config/local/git_user_config` に Git 用のユーザー設定を記述する。

例: 基本のユーザー設定と、特定ディレクトリ配下の Git リポジトリのみで利用する設定を読み込む

```gitconfig
[user]
  name = USERNAME_OF_GITHUB
  email = EMAIL_ADDRESS@GITHUB

[includeIf "gitdir:~/Projects/SOME_COMPANY/"]
  path = PATH_OF_ONLY_SOMECOMPANY_CONFIG_FILE
```

### ssh鍵によるコミット署名設定

以下のコマンドでssh鍵によるGitコミットの署名を設定可能。
リポジトリごとに署名鍵を変更する場合は最後のコマンドをローカルとして各リポジトリで行うなどの工夫が必要。

```sh
git config gpg.format ssh
git config commit.gpgsign true
git config user.signingkey "$(ssh-add -L | grep 'SOME_CONDITION')"
```

## 設定内容

- パッケージ管理ツールを利用したセットアップ
- Bash
- SSH キーの共有（Bitwarden 利用）
  - <https://github.com/joaojacome/bitwarden-ssh-agent> の`6237a3604`を利用
  - 使用する場合、利用者各個人で内容確認推奨
- [Starship](https://starship.rs/ja-jp/)
- [mise (alt asdf)](https://github.com/jdx/mise)
- Git config
  - diff として delta を利用
  - 便利エイリアスを登録（よく使うコマンドの短縮など）
- 作成したスクリプトの共有

[chezmoi's doc](https://www.chezmoi.io)

### Starship の主な設定内容

- プロンプトは 2 行に分け、1 行目を情報表示に利用する
- 実行結果末尾に改行がない場合付与する
- 設定したモジュールに関して、カッコ（"[" "]"）で囲い表示
- AWS の日本リージョンに関しては短縮表記を利用
- 実行に 10 秒以上かかったコマンドはかかった秒数を表示
- カレントディレクトリは直近 2 つのディレクトリのみ表示
- Git:ブランチを表示（`main`および`master`の場合は表示しない）
- Git:ワークツリーの追加行数・削除行数を表示
- Git:リポジトリの状態を表示（`!`: 差分あり、など）
- 2 行目プロンプトに時刻を表示

### 主な Bash 用エイリアス

| エイリアス  | 展開                                          | 備考                 |
|--------|-----------------------------------------------|----------------------|
| `l`    | `ls`                                          | ディレクトリ配下の一覧      |
| `ll`   | `ls -alF`                                     | リスト表示              |
| `sl`   | `ls`                                          | タイポ対策              |
| `cd..` | `cd ..`                                       | タイポ対策              |
| `..`   | `cd ..`                                       |                      |
| `...`  | `cd ../../`                                   |                      |
| `.2`   | `cd ../../`                                   |                      |
| `.3`   | `cd ../../../`                                |                      |
| `cg`   | `cd $(git rev-parse --show-toplevel)`         | Git リポジトリのトップに cd する |
| `gs`   | `git status`                                  | タイポ対策              |
| `tf`   | `terraform`                                   |                      |
| `g`    | `git`                                         |                      |
| `d`    | `docker`                                      |                      |
| `dc`   | `docker compose`                              |                      |
| `ddu`  | `docker compose down && docker comopse up -d` |                      |

### 主な Git コマンドのエイリアス

| エイリアス   | 展開                                                                                                           | 備考                                      |
|---------|----------------------------------------------------------------------------------------------------------------|-------------------------------------------|
| `a`     | `add`                                                                                                          | ワークツリーのファイルをインデックスに登録する                 |
| `au`    | `add -u`                                                                                                       | インデックスに登録されているファイルに差分があれば登録する       |
| `br`    | `branch`                                                                                                       | ブランチ                                      |
| `c`     | `commit`                                                                                                       | コミット                                      |
| `cam`   | `commit --amend -m`                                                                                            | メッセージを記載して amend                        |
| `caum`  | `commit --amend -am`                                                                                           | 更新ファイルを追加しメッセージを記載して amend          |
| `cmm`   | `commit -m`                                                                                                    | メッセージを記載して commit                       |
| `cum`   | `commit -am`                                                                                                   | 更新ファイルを追加しメッセージを記載して commit         |
| `co`    | `checkout`                                                                                                     | チェックアウト                                   |
| `dns`   | `diff --name-status`                                                                                           | 差分種類のみ確認                            |
| `fsw`   | `!git for-each-ref --format '%(refname:short)' refs/heads \| fzf \| xargs git switch`                          | fzf を利用して switch                        |
| `fsn`   | `!git branch --no-merged origin/master --format='%(refname:short)' \| fzf \| xargs git switch`                 | マージされていないブランチに fzf を利用して switch         |
| `fw`    | `!git for-each-ref --format '%(refname:short)' refs/heads \| fzf \| xargs git switch`                          | fw と同じ                                   |
| `graph` | `log --graph --date=short --decorate=short --pretty=format:'%Cgreen%h %Creset%cd %Cblue%cn %Cred%d %Creset%s'` | コミットグラフを表示                              |
| `l`     | `log`                                                                                                          | ログ                                        |
| `l5`    | `log --first-parent -n 5`                                                                                      | 5 個前までのログ                               |
| `l10`   | `log --first-parent -n 10`                                                                                     | 10 個前までのログ                              |
| `l15`   | `log --first-parent -n 15`                                                                                     | 15 個前までのログ                              |
| `pl`    | `pull`                                                                                                         | プル                                        |
| `poh`   | `push origin HEAD`                                                                                             | origin に現在のブランチを push                   |
| `rst`   | `reset`                                                                                                        | リセット                                      |
| `rh`    | `reset --hard`                                                                                                 | ワークツリーとインデックスを指定の状態に変更（未指定:HEAD） |
| `rmc`   | `rm --cached`                                                                                                  | インデックスへの登録のみ削除                        |
| `s`     | `status`                                                                                                       | ステータスを表示                                |
| `ss`    | `status`                                                                                                       | ステータスを表示                                |
| `sw`    | `switch`                                                                                                       | ブランチを変更                                 |
| `top`   | `rev-parse --show-toplevel`                                                                                    | Git リポジトリのトップレベルパスを表示                   |
| `wip`   | `stash`                                                                                                        | 一時領域関連                              |
| `wipl`  | `stash list`                                                                                                   | 一時領域のリストを表示                         |
| `wips`  | `stash push`                                                                                                   | 更新内容を一時領域に保存                    |
| `wipp`  | `stash pop`                                                                                                    | 一時領域から更新を取得                       |

## チェック内容

### shfmt

シェルスクリプトファイルは更新時にshfmtによってチェックされている。

### markdownlint-cli2

フォルダ内の Markdown ファイルは更新時にmarkdownlint-cli2によってチェックされている。

NOTE: markdownlintによるチェックとの違いは要検証

## log

### rtx -> mise への名前変更に追従

mise のインストールを含めたマイグレーションスクリプト。
以下 3 つについては mise 標準のマイグレーションではだめなことがわかっているので自前で実施。

- Git の再インストール
- Python の再インストール
- Ruby の再インストール

```shell
if [ ! -x "$HOME/.local/bin/mise" ]; then
  gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 0x7413A06D
  curl https://mise.jdx.dev/install.sh.sig | gpg --decrypt > install.sh
  sh ./install.sh
  rm ./install.sh
fi
if [ -x "$HOME/.local/share/rtx/bin/rtx" ]; then
  "$HOME/.local/share/rtx/bin/rtx" uninstall git --all
  "$HOME/.local/bin/mise" use -yg git
  for v in $(~/.local/share/rtx/bin/rtx ls python | cut -d " " -f 2); do
    "$HOME/.local/bin/mise" install -y python@$v
  done
  for v in $(~/.local/share/rtx/bin/rtx ls ruby | cut -d " " -f 2); do
    "$HOME/.local/bin/mise" install -y ruby@$v
  done
fi
```
