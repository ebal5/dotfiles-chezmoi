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
- **mise**: 言語ランタイムのみ（Node.js, Python）
- **winget**（Windows）: Nix CLIツールのWindows対応版 + Windows専用アプリ
- **uvx/bunx shim**（`dot_config/shim-definitions`）: `chezmoi apply`時に`~/.scripts/`へラッパースクリプトを自動生成。新ツール追加は定義ファイルに1行追加するだけ
- 判定基準: CLIツール→Nix、ビルド依存→APT、ランタイム→mise、root権限必要→APT、Pythonツール(ruff等)→uvx shim、JSツール(markdownlint-cli2等)→bunx shim

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

## 詳細ガイドライン

ファイルタイプ別の詳細は `.claude/rules/` を参照。
