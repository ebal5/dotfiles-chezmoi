# Shared Development Standards

This file contains Claude Code standards applied across all projects.

## Tools

Use specialized tools instead of shell commands:

- **Read files**: Use Read tool (not `cat`, `head`, `tail`)
- **Edit files**: Use Edit tool (not `sed`, `awk`)
- **Create files**: Use Write tool (not `echo`, `cat` heredoc)
- **Search files**: Use Glob/Grep tools (not `find`, `grep`)
- **Explore codebase**: Use Task tool with Explore agent for open-ended searches

## Docker

- Use `docker compose` instead of the deprecated `docker-compose` command

## Git

- **Gitignore**: Add credentials, secrets, sensitive data (`.env*`, `*.key`, `credentials.*`, etc.) to `.gitignore`

## Performance

- Be aware of token usage; use offset/limit when reading large files
- Only read necessary parts of files
