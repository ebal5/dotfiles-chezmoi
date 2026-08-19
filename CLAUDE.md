# CLAUDE.md

このファイルは、Claude Code がこのリポジトリで作業する際のガイダンスを提供します。

## リポジトリ概要

Ubuntu/WSL2環境向けのChezmoiで管理された個人用dotfilesリポジトリ。
シェル環境、開発ツール、設定ファイルのセットアップを自動化する。

## Chezmoi命名規則

リポジトリ内のファイル名はChezmoi独自の命名規則に従う：

| プレフィックス/サフィックス | 意味 | 例 |
| --- | --- | --- |
| `dot_` | `.`に変換 | `dot_zshrc` → `~/.zshrc` |
| `executable_` | 実行権限を付与 | `executable_once_setup_ubuntu.sh.tmpl` |
| `private_` | パーミッション600 | `private_dot_ssh/` |
| `.tmpl` | Goテンプレートとして処理 | `dot_zshrc.tmpl` |
| `.src` | シンボリックリンクのソース | `settings.json.src` |
| `symlink_` | シンボリックリンクを作成 | `symlink_settings.json.tmpl` |
| `run_after_` | apply後に毎回実行 | `run_after_setup_powershell_profile.ps1.tmpl` |
| `executable_once_` | 初回のみ実行 | `executable_once_setup_ubuntu.sh.tmpl` |

## テンプレートパターン

`.tmpl`ファイルではGoテンプレート構文でプラットフォーム分岐を行う：

- OS判定: `{{ if eq .chezmoi.os "linux" }}`
- ディストロ判定: `{{ if eq .chezmoi.osRelease.id "ubuntu" }}`
- WSL検出: `{{ if .chezmoi.kernel.osrelease | lower | contains "microsoft" }}`
- Windows除外: `{{ if ne .chezmoi.os "windows" }}`

## ツール管理方針

- **Nix**（`flake.nix`）: CLIツール・開発コマンドの宣言的管理（starship, delta, fzf, ripgrep, git, chezmoi等）
- **APT**: システム基盤・ビルド依存（lib*-dev, build-essential等）+ ブートストラップ用最小限ツール + root権限で使うツール（nmap, vim）
- **mise**: プロジェクトごとにバージョンを固定する必要があるツール（Node.js, Python等のランタイム、shellcheck, shfmt等）
- **winget**（Windows）: Nix CLIツールのWindows対応版 + Windows専用アプリ
- **uvx/pnpm shim**（`dot_config/shim-definitions`）: `chezmoi apply`時に`~/.scripts/`へラッパースクリプトを自動生成。新ツール追加は定義ファイルに1行追加するだけ
- 判定基準: CLIツール→Nix、ビルド依存→APT、PJごとのバージョン固定が必要→mise、root権限必要→APT、Pythonツール(ruff等)→uvx shim、JSツール(markdownlint-cli2等)→pnpm shim
- Nixはグローバルに1バージョンしか置けないため、PJごとに異なるバージョンを使い分けるツール（terraform等）はNixではなくmiseで管理する。
  ただしグローバルの`~/.config/mise/config.toml`ではなく、各プロジェクトの`mise.toml`に書く

## 機械固有設定

マシン固有の設定はリポジトリに含めず、以下のファイルでオーバーライドする：

- `~/.config/local/profile.local` - ログイン環境変数
- `~/.config/local/shellrc.local` - 対話シェル設定
- `~/.config/local/git_user_config` - Gitユーザー情報
- `~/.config/local/tmux_repo_names` - tmuxタイトル用リポジトリ短縮名

## 開発コマンド

```bash
# シェルスクリプトのフォーマット
shfmt -i 2 -ci -w .

# シェルスクリプトの静的解析
shellcheck $(shfmt -f .)

# Markdownのリント
markdownlint-cli2 .
```

GitHub Actionsで上記に加え、JSON Schema検証、E2Eテスト（Ubuntu/Windows）が自動実行される。

## ファイル追加時の注意

- 開発用ファイル（ドキュメント、設定等）を追加した場合、`.chezmoiignore`への追記が必要な場合がある
- ホームディレクトリに展開不要なファイルは`.chezmoiignore`で除外する

## Claude Code固有の注意

- `git add`と`git commit`は`&&`で繋げず、**別々のBash呼び出し**で実行すること。
  許可ツール設定が個別コマンドパターンのため、連結すると毎回許可確認が必要になる
- `dot_claude/`内のファイルは`~/.claude/`に展開される（Claude Codeのグローバル設定）
- `settings.json.src`に絶対パス（`/home/<user>/...`）を含むフックが混ざっていたら、
  外部ツールが`~/.claude/settings.json`（このファイルへのシンボリックリンク）を
  書き換えた痕跡。共有設定に固定パスを入れず、`~/.scripts/`のラッパー経由にする
  （herdrの例は[README](README.md)の「フック」節を参照）
- フックスクリプトは`set -e`を使っても最終的に`exit 0`で終わること。
  非ゼロ終了はセッション側にエラーとして表示される

## Markdownテーブルスタイル

CJK文字を含むテーブルはcompact style（`| --- |`セパレータ、最小パディング）で記述すること。
aligned styleはCJK文字幅の違いでMD060違反となる。

## 詳細ガイドライン

ファイルタイプ別の詳細は `.claude/rules/` を参照。
