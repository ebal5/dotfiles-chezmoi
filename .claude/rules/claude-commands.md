---
paths: dot_claude/**
description: Claude Codeカスタムコマンド管理
---

# Claude Code カスタムコマンド

`dot_claude/commands/` でグローバルカスタムコマンドを管理。
`chezmoi apply` により `~/.claude/` に展開される。

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
3. `chezmoi apply` で展開後、`/category:name` で使用可能

## 設定ファイルの構造

- `settings.json.src` / `dot_mcp.json.src` - 実体ファイル
- `symlink_*.tmpl` - 上記への動的シンボリックリンク

## 注意事項

- コマンドファイルはフロントマターから始まるため、markdownlint の MD041 ルールと互換性がない
