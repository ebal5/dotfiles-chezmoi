# zsh 標準機能プロンプト（Starship 不要版）

starship などの追加ツールを入れられない環境向けに、zsh の標準機能だけで
[`dot_config/starship.toml`](../../dot_config/starship.toml) の見た目を
できる限り再現したプロンプト設定（`prompt.sh`）です。

主にお仕事 Mac での利用を想定していますが、Mac 特化の設定は含まれていません。

## 位置づけ

- このディレクトリは **chezmoi 管轄外**（`.chezmoiignore` で除外）です。
  `chezmoi apply` ではホームディレクトリに展開されません。
- 必要になったときに、手動でコピー or source して使うためのスニペット置き場です。

## 前提

- **Nerd Font** が必須です（  󰏫 󱇪 󱁢 などのアイコンを使用）。
- zsh の標準機能（`vcs_info` / `prompt_subst`）のみで動作し、外部ツールに依存しません。

## 再現している要素

| 要素 | 内容 |
| --- | --- |
| 時刻 | `⌚[ HH:MM:SS ]`（淡いグレー） |
| ディレクトリ | 直近2階層をシアン表示、home は 🏠 |
| Git | ブランチ名（main/master は非表示）、未ステージ `!`/ステージ済み `+` |
| AWS | `AWS_PROFILE` をオレンジ表示 |
| Terraform | `.terraform/environment` のワークスペースを紫表示 |
| 実行時間 | 5秒以上のコマンドを黄色で `⌛ Ns` 表示 |
| Vi モード | insert は緑のペン 󰏫 、normal は赤の Vim ロゴ |
| 終了ステータス | 直前コマンドの成否で `❯` を緑/赤に切替 |

starship 版との差分として、`git_metrics`（追加/削除行数）や `memory_usage` などは
標準機能だけでは再現が難しいため省略しています。

## 使い方

### 一時的に試す

```sh
source /path/to/dotfiles/extras/zsh-standalone-prompt/prompt.sh
```

### 常用する（starship が入っていない環境）

マシン固有設定ファイル `~/.config/local/shellrc.local` から読み込むのが手軽です
（このファイルはリポジトリ管理外で、`dot_zshrc` の末尾で source されます）。

```sh
# ~/.config/local/shellrc.local
[[ -f "$HOME/path/to/prompt.sh" ]] && source "$HOME/path/to/prompt.sh"
```

`dot_zshrc` では starship が見つかったときだけ初期化されるため
（`command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"`）、
starship 未インストール環境ではこの `prompt.sh` がそのまま有効になります。

> [!NOTE]
> Vi モード自体は `dot_zshrc` 側でも標準で有効化されています（`bindkey -v`）。
> この `prompt.sh` を読み込むとモードインジケータの表示込みで上書きされます。
