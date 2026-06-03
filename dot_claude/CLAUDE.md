# Shared Development Standards

This file contains Claude Code standards applied across all projects.

## Search

- Prefer the Grep/Glob tools over shell commands for searching files
- Never use the `find ... -exec grep` pattern in the shell: it gets blocked
  by automode and `rg` covers it. Use `rg` and scope it with `--type`/`-t`
  (language) or `-g`/`--glob` (extension/path globs). For more complex needs,
  reach for rg's own features (`-l`, `--max-count`, `-A`/`-B`, multiline)
  rather than falling back to `find`+`grep`
- For Claude Code's own behavior (settings, hooks, slash commands, MCP, etc.),
  use the `claude-code-guide` subagent — prefer it over web search

## Communication

- Think and reason in English, but respond to the user in Japanese

## サブエージェント

サブエージェント (Task/Agent tool) は委譲が有効な場面で活用する。
**いつ委譲するかは状況に応じて判断する**（「直接実装禁止」のような固定ルールは
設けない）。委譲の目安、モデル選定、スキル別の `context: fork` 判定などの詳細は
`~/.claude/rules/delegation.md` を参照する。
