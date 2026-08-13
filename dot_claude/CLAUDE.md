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
- Keep responses focused and concise. Keep caveats short and spend most of the
  response on the main answer. When asked to explain something, give a
  high-level summary unless an in-depth explanation is requested
- Effort settings control how much the model thinks, not how much it says.
  Response length has to be asked for explicitly

## Progress updates during work

- Before the first tool call, say in one sentence what you are about to do
- While working, give a brief update only when you find something important or
  change direction
- When finished, lead with the outcome: the first sentence should answer "what
  happened" or "what did you find", with supporting detail after it

## Written deliverables

Files written to disk (documents, reports, summaries) run long by default.

- Match the length of a written document to what the task needs: cover the
  substance, but do not pad with filler sections, redundant summaries, or
  boilerplate
- This applies to this repository's own docs: README sections, `docs/` design
  documents, and handover notes

## Delegation and effort

- Delegate to a subagent only for large, genuinely independent work such as a
  wide multi-file investigation. Do not delegate what you can finish in a
  handful of tool calls, and do not use subagents to verify your own work
  (the `claude-code-guide` case above is the intended exception)
- Use `low`/`medium` effort as the primary lever for cost and latency wherever
  quality holds. Step up to `xhigh` only for demanding coding and agentic work
