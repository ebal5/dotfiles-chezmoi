---
paths: dot_*, .chezmoiignore, .chezmoi*
description: Chezmoi設定管理ガイドライン
---

# Chezmoi管理

## 基本コマンド

- `chezmoi apply` - 設定変更をホームディレクトリに適用
- `chezmoi edit <file>` - 設定ファイルを編集
- `chezmoi diff` - ソースとターゲット状態の差分を表示
- `chezmoi cd` - chezmoiソースディレクトリに移動

## ファイル管理

- `.chezmoiignore` でホームディレクトリに適用しないファイルを指定
- 新しいドキュメントや開発用ファイルを追加した場合は`.chezmoiignore`への追記を検討
- **`.chezmoiignore`と`.chezmoiremove`のパターンはターゲットパス**（ホーム上での名前）で書く。
  ソース名（`dot_`/`executable_`/`private_`/`run_`等のプレフィックスや`.tmpl`サフィックス）で
  書くと何にもマッチせず、しかもエラーも出ないため「除外したつもり」で気づけない。
  例: `executable_once_setup_ubuntu.sh.tmpl`ではなく`once_setup_ubuntu.sh`と書く
  （`.github/scripts/check-repo-conventions.sh`が検出する）
- `run_`スクリプトを特定プラットフォームで動かしたくない場合、`.chezmoiignore`ではなく
  スクリプト側のテンプレート条件で囲む。chezmoiはレンダリング結果が空白のみのスクリプトを
  実行しないため、`{{ if eq .chezmoi.os "windows" }}`で囲めば他OSでは走らない

## テンプレートの注意点

- `run_after_`スクリプトで条件分岐（`{{ if ... }}`）をshebang行の前に置く場合、
  trim marker（`{{ if ... -}}`）を使うこと。そうしないとshebangが2行目になり実行に失敗する
  （`.github/scripts/check-repo-conventions.sh`が検出する）

## shim管理（uvx/pnpm ラッパースクリプト）

- 定義ファイル: `dot_config/shim-definitions`（形式: `runner:package[:alias]`）
- `chezmoi apply`時に`run_after_generate_shims.sh.tmpl`（本体は`scripts/generate-shims.sh`）が
  `~/.scripts/`にshimを自動生成
- 新しいuvx/pnpmツールを追加する場合は定義ファイルに1行追加するだけでよい
- `pnpm`ランナーは生成時に`pnpm dlx`にマッピングされる
- `@version`付きパッケージはalias必須（例: `uvx:tool@1.2.3:toolname`）。
  違反すると生成時に黙ってスキップされるため、`check-repo-conventions.sh`が事前に検出する
- shimにはマーカーコメントが含まれ、定義から削除されたshimは自動クリーンアップされる
- `~/.npmrc`で`minimum-release-age=4320`を設定（サプライチェーン攻撃対策、3日）
