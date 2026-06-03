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
