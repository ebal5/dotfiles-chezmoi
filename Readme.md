# My Dotfiles Managemen using Chezmoi

Chezmoiを利用して作成したdotfiles。
動作確認は今のところUbuntuのみ。

## installation

### Ubuntu

```bash
# 一時的に使うchezmoiをインストールする
sh -c "$(curl -fsLS get.chezmoi.io)"
# このリポジトリを所定ディレクトリにクローンし適用
${HOME}/bin/chezmoi init https://github.com/ebal5/dotfiles-chezmoi.git
${HOME}/bin/chezmoi apply
# 初期スクリプトを起動する
${HOME}/once_setup_ubuntu.sh
# 初期に使用したchezmoiを削除しrtxでインストールしたものを利用するようにする
rm ~/bin/chezmoi
```

## install後の作業

`~/.config/local/git_user_config` にGit用のユーザー設定を記述する。

例: 基本のユーザー設定と、特定ディレクトリ配下のGitリポジトリのみで利用する設定を読み込む
```
[user]
	name = USERNAME_OF_GITHUB
	email = EMAIL_ADDRESS@GITHUB

[includeIf "gitdir:~/Projects/SOME_COMPANY/"]
	path = PATH_OF_ONLY_SOMECOMPANY_CONFIG_FILE
```

## 設定内容

- パッケージ管理ツールを利用したセットアップ
- Bash
- SSHキーの共有（Bitwarden利用）
  - https://github.com/joaojacome/bitwarden-ssh-agent の`6237a3604`を利用
  - 使用する場合、利用者各個人で内容確認推奨
- [Starship](https://starship.rs/ja-jp/)
- [RTX (alt asdf)](https://github.com/jdx/rtx)
- Git config
  - diffとしてdeltaを利用
  - 便利エイリアスを登録（よく使うコマンドの短縮など）
- 作成したスクリプトの共有

[chezmoi's doc](https://www.chezmoi.io)
