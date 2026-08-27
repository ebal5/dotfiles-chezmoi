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
- markdownlint-cli2 だけはバージョンを固定する（現在 `0.23.2`）。`.markdownlint-cli2.yaml`で
  MD060の`style`を明示しており、ルールの挙動がバージョンに依存するため、CIとローカルで
  版が食い違うと「ローカルで通ったのにCIで落ちる」が起きる。
  **固定箇所は`dot_config/shim-definitions`の1行だけ**。CI（`.github/workflows/linter.yaml`）は
  そこからバージョンを抽出して`npm install -g`する。更新時に直すのはこの1箇所で、
  乖離を検出する仕組みではなく乖離が起こりえない形にしてある
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

# Markdownのリント（`.`はトップレベルしか見ないためグロブで指定する）
markdownlint-cli2 "**/*.md"
```

GitHub Actionsで上記に加え、JSON Schema検証、E2Eテスト（Ubuntu/Windows）が自動実行される。

## ファイル追加時の注意

- 開発用ファイル（ドキュメント、設定等）を追加した場合、`.chezmoiignore`への追記が必要な場合がある
- ホームディレクトリに展開不要なファイルは`.chezmoiignore`で除外する。
  **書くのはソース名ではなくターゲットパス**（`executable_once_setup_ubuntu.sh.tmpl`ではなく
  `once_setup_ubuntu.sh`）。ソース名で書いても何にもマッチせず、エラーも出ない

## Claude Code固有の注意

- `dot_claude/`内のファイルは`~/.claude/`に展開される（Claude Codeのグローバル設定）
- `settings.json.src`に絶対パス（`/home/<user>/...`）を含むフックが混ざっていたら、
  外部ツールが`~/.claude/settings.json`（このファイルへのシンボリックリンク）を
  書き換えた痕跡。共有設定に固定パスを入れず、`~/.scripts/`のラッパー経由にする
  （herdrの例は[README](README.md)の「フック」節を参照）
- 通知系フックスクリプト（tmuxタイトル等）は`set -e`を使っても最終的に`exit 0`で終わること。
  意図しない非ゼロ終了はセッション側にエラーとして表示される。
  例外はモデルへのフィードバックを目的とするフック（`.claude/hooks/lint-edited-file.sh`）で、
  lintの指摘をstderrに出して`exit 2`で返すのが正しい終わり方
- `Write`/`Edit`後は`.claude/hooks/lint-edited-file.sh`がPostToolUseフックとして
  ファイル種別ごとにlintを実行する（`.sh`→shfmt+shellcheck、`.md`→markdownlint-cli2、
  `.tmpl`はスキップ）。編集のたびに手でlintを流す必要はない

## 静的検査で担保している規約

以下は文章での約束ではなくリンターが機械的に検出する。ローカルではPostToolUseフック、
コミット時はprek、PRではCIが同じチェックを実行する。

| 規約 | 実装 |
| --- | --- |
| テーブルはcompact style（最小パディング）。CJK文字幅でaligned styleが崩れるため | markdownlint MD060（`style: compact`） |
| 先頭に条件分岐を置く`.tmpl`で、その後（空行を挟んでもよい）がshebangならtrim marker（`-}}`）必須 | `.github/scripts/check-repo-conventions.sh` |
| shim定義は`runner:package[:alias]`形式、`@`を含むpackageはalias必須 | 同上 |
| `.chezmoiignore`/`.chezmoiremove`はソース名ではなくターゲットパスで書く | 同上 |
| markdownlint-cli2のバージョンはshim定義が単一情報源。CIが直書きに戻していないこと | 同上 |
| 共有設定（`dot_claude/*.src`）にマシン固有・組織固有の値を入れない | `.github/scripts/check-shared-settings.sh` |
| シェルスクリプトの品質（`[[ ]]`推奨、クォート漏れ等） | shellcheck（`.shellcheckrc`で`enable=all`） |

新しい規約を足すときは、機械的に判定できるなら文章ではなく上記のいずれかに実装する。

検査されない範囲も把握しておくこと:

- **`.tmpl`のシェルコードは検査されない**。Goテンプレート構文をshfmt/shellcheckが
  パースできないため。これを避けるために、`.tmpl`には分岐だけを置いて
  シェルコードは`scripts/`配下の素の`.sh`に出す（次節）。現状`.tmpl`に残っている
  シェルコードはランチャー3本の計6行だけで、その失敗モード（shebangが1行目に
  来ない）は`check-repo-conventions.sh`の規約1が検出する
- テーブル区切り行のダッシュ長（`| ------ |`）はMD060の対象外。表示上無害なので許容する
- **規約4は`.chezmoiignore`の書き方（ソース名かターゲットパスか）しか見ない**。
  ターゲットパスの形をしていて実際には何にもマッチしないパターン（typoや
  存在しないファイル）は検出できない。実挙動側はE2Eの除外アサーション
  （`.github/workflows/e2e-test-*.yaml`）が担保する

## `.tmpl`ランチャーと本体スクリプトの分離

シェルコードを持つ`.tmpl`は、条件分岐だけを残したランチャーにして、本体を
`scripts/`配下の素の`.sh`に置く。素の`.sh`になれば既存のshfmt/shellcheck/prek/CI/
PostToolUseフックがそのまま効くため、テンプレート用の検査機構を別に作らずに済む。

| ランチャー | 本体 | 備考 |
| --- | --- | --- |
| `run_after_generate_shims.sh.tmpl` | `scripts/generate-shims.sh` | 毎回走るのでハッシュ不要 |
| `run_onchange_after_install_herdr_plugins.sh.tmpl` | `scripts/install-herdr-plugins.sh` | 本体と定義ファイルの両方のハッシュを埋める |
| `executable_once_setup_ubuntu.sh.tmpl` | `scripts/setup-ubuntu.sh` | 手動実行される展開物。再実行判定がないのでハッシュ不要 |

守ること:

- `scripts/`は`.chezmoiignore`でホームへ展開しない。ランチャーが
  `{{ .chezmoi.sourceDir }}`経由で`exec`する
- **`run_once_`/`run_onchange_`のランチャーには`{{ include "<本体パス>" | sha256sum }}`を
  コメントで埋めること**。再実行はレンダリング結果のハッシュで判定されるため、
  埋めないと本体を編集しても再実行されない（実測で確認済み）
- 素の`.sh`を`#!/bin/sh`で書く場合は先頭に`# shellcheck shell=sh`を置く。
  `.shellcheckrc`の`shell=bash`がshebangを上書きするため、付けないと
  bash前提の指摘（SC2292等）が誤って出る
- テンプレート側の条件式は現状の短絡評価を壊さないこと。
  `executable_once_setup_ubuntu.sh.tmpl`の`REQUIRE_GUI`は
  `and`の短絡で`.chezmoi.requireGUI`に触れずに済ませている。無条件に評価する形へ
  変えると、このキーを設定していないマシンでレンダリングが失敗する

## 詳細ガイドライン

ファイルタイプ別の詳細は `.claude/rules/` を参照。
