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
| Vi モード | insert=緑のペン 󰏫 +ビームカーソル、normal=赤の Vim ロゴ+ブロックカーソル |
| 終了ステータス | 直前コマンドの成否で `❯` を緑/赤に切替 |

## starship 版との表示比較

通常設定（starship 利用時）と、この `prompt.sh`（starship 無し版）の表示差分は以下の通り。
starship 未インストール環境では `dot_zshrc` の starship 初期化がスキップされ、
この `prompt.sh` を読み込めば下表の「prompt.sh」列の見た目になる。

| 要素 | starship 版（通常） | prompt.sh（無し版） |
| --- | --- | --- |
| 時刻 | `⌚[ HH:MM:SS ]` | 同左（同一書式） |
| ディレクトリ | 直近2階層・home 🏠 | 同左 |
| Git ブランチ | main/master 非表示 | 同左 |
| Git 変更状態 | starship 既定の表示 | 未ステージ `!`/ステージ済 `+` |
| Git 変更行数 | `git_metrics` で +/- 表示 | ✗ 省略（標準機能で再現困難） |
| AWS | `[profile]` オレンジ | 同左 |
| Terraform | `[workspace]` 紫 | 同左 |
| メモリ使用率 | `memory_usage` で表示 | ✗ 省略 |
| 言語ランタイム等 | 各モジュールが自動表示 | ✗ 省略 |
| 実行時間 | 5秒以上を `⌛` 表示 | 同左 |
| Vi モード | `character` の vicmd_symbol +カーソル形状 | 専用アイコン（insert 󰏫 / normal ）+カーソル形状 |
| 終了ステータス | `❯` の色で成否 | `❯` の色で成否（モードアイコンと分離表示） |
| C-a/C-e 等 | dot_zshrc 側で insert に付与 | prompt.sh 内で insert に付与 |

`git_metrics`（追加/削除行数）や `memory_usage`、各種ランタイム表示などは
zsh 標準機能だけでは再現が難しいため省略している。

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
