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
rm -rf ~/bin
```

## 設定内容

- パッケージ管理ツールを利用したセットアップ
- Bash
- SSHキーの共有（Bitwarden利用）
- [Starship](https://starship.rs/ja-jp/)
- [RTX (alt asdf)](https://github.com/jdx/rtx)
- Git config
- 作成したスクリプトの共有

[chezmoi's doc](https://www.chezmoi.io)
