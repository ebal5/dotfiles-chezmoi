# Shared Development Standards

This file contains Claude Code standards applied across all projects.

## Tools

Use specialized tools instead of shell commands:

- **Read files**: Use Read tool (not `cat`, `head`, `tail`)
- **Edit files**: Use Edit tool (not `sed`, `awk`)
- **Create files**: Use Write tool (not `echo`, `cat` heredoc)
- **Search files**: Use Glob/Grep tools (not `find`, `grep`)
- **Explore codebase**: Use Task tool with Explore agent for open-ended searches

## Python

- **New projects**: Use `uv` for environment management and `ruff` for linting/formatting (unless otherwise specified in project CLAUDE.md)

## Docker

- Use `docker compose` instead of the deprecated `docker-compose` command

## Git

- **Gitignore**: Add credentials, secrets, sensitive data (`.env*`, `*.key`, `credentials.*`, etc.) to `.gitignore`

## Performance

- Be aware of token usage; use offset/limit when reading large files
- Only read necessary parts of files

## Quality Assurance

- Run tests, linting, and formatting before pushing code

## Communication

- Think and reason in English, but respond to the user in Japanese

## Workflow

- **Incremental approach**: Break large changes into multiple smaller steps with verification after each step
- **Confirmation**: Always confirm with the user before executing destructive operations (delete, overwrite, force push, etc.)
- **Error handling**: Investigate and understand errors thoroughly rather than making assumptions or guessing solutions
