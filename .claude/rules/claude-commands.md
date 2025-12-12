---
paths: dot_claude/**
description: Claude Codeカスタムコマンド管理
---

# Claude Code カスタムコマンド

このリポジトリでは、Claude Code のグローバルカスタムコマンドを `dot_claude/commands/` で管理しています。

## ディレクトリ構造

```text
dot_claude/
├── commands/           # カスタムスラッシュコマンド
│   ├── docker/
│   │   └── compose-up.md
│   ├── git/
│   │   └── sync-from-origin.md
│   ├── mcp/
│   │   ├── aws.md
│   │   └── terraform.md
│   ├── project/
│   │   └── init.md     # プロジェクト初期設定
│   └── python/
│       ├── lint.md
│       ├── test.md
│       └── security.md
├── dot_mcp.json        # グローバルMCPサーバー設定
├── executable_stop-hook-git-check.sh  # Stopフック
├── settings.json       # グローバル設定
└── CLAUDE.md           # ユーザーグローバル指示
```

`chezmoi apply` により `~/.claude/` に展開されます。

## コマンドファイルの形式

```markdown
---
description: コマンドの説明（/help で表示される）
allowed-tools: Bash(command:*), Bash(other:*)
argument-hint: [引数の説明（オプション）]
---

Claudeへの指示文をここに記述。
```

## allowed-tools の書き方

- 最小権限の原則に従い、必要なコマンドのみ許可
- `Bash` のみだと全コマンド実行可能になるため非推奨
- 例: `Bash(docker compose:*)`, `Bash(uv run ruff:*)`

## 新しいコマンドの追加

1. `dot_claude/commands/<category>/<name>.md` を作成
2. フロントマターに `description` と `allowed-tools` を記述
3. `chezmoi apply` で `~/.claude/commands/` に展開
4. `/category:name` で使用可能

## プロジェクト初期化コマンド

- `/project:init` - Claude Code用のプロジェクト初期設定
  - `.gitignore`にClaude Code関連エントリを追加
  - `.claude/`ディレクトリを作成
  - `CLAUDE.md`の作成を提案

## MCPセットアップコマンド

プロジェクトにMCPサーバーを追加するコマンド:

- `/mcp:aws` - AWS MCPサーバーを追加
  - 認証不要: `aws-knowledge`（ドキュメント）→ `.mcp.json`
  - 認証必要: `aws-api`（CLI操作）→ `.claude/.mcp.json`（ユーザー確認後）
- `/mcp:terraform` - Terraform MCPサーバーを追加
  - 認証不要: `terraform`（Registry検索）→ `.mcp.json`
  - 認証必要: `terraform-cloud`（HCP操作）→ `.claude/.mcp.json`（ユーザー確認後）

認証が必要なサーバーは `.claude/.mcp.json` に追加され、`.gitignore` にも追記されます。

## 注意事項

- `.chezmoiignore` でトップレベルの `*.md` は除外されているが、`dot_claude/` 内のファイルは適用対象
- コマンドファイルはフロントマターから始まるため、markdownlint の MD041 ルールと互換性がない
