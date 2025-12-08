#!/bin/bash

# SessionStart hook: Auto-detect base branch for stop hook comparison
# This sets CLAUDE_STOP_HOOK_BASE_BRANCH environment variable

# Exit early if not in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  exit 0
fi

current_branch=$(git branch --show-current)

# Exit if not on a branch (detached HEAD)
if [[ -z "$current_branch" ]]; then
  exit 0
fi

# Exit if branch already exists on remote (stop hook will compare against origin/<branch>)
if git rev-parse "origin/$current_branch" >/dev/null 2>&1; then
  exit 0
fi

# Check if manual config exists (takes priority, no need to auto-detect)
if git config "branch.${current_branch}.stop-hook-base-branch" >/dev/null 2>&1; then
  exit 0
fi
if git config "stop-hook.base-branch" >/dev/null 2>&1; then
  exit 0
fi

# Try to auto-detect the base branch
base_branch=""

# Method 1: Try fork-point detection for common base branches
for candidate in origin/main origin/master origin/develop; do
  if git rev-parse "$candidate" >/dev/null 2>&1; then
    # Check if current branch has this as an ancestor
    if git merge-base --is-ancestor "$candidate" HEAD 2>/dev/null; then
      base_branch="$candidate"
      break
    fi
  fi
done

# Method 2: If no common base found, try to find the most recent common ancestor
if [[ -z "$base_branch" ]]; then
  # Try origin/HEAD as fallback
  if git rev-parse "origin/HEAD" >/dev/null 2>&1; then
    base_branch="origin/HEAD"
  fi
fi

if [[ -n "$base_branch" && -n "${CLAUDE_ENV_FILE:-}" ]]; then
  echo "export CLAUDE_STOP_HOOK_BASE_BRANCH='$base_branch'" >>"$CLAUDE_ENV_FILE"
  echo "[SessionStart] Auto-detected base branch: $base_branch" >&2
elif [[ -z "$base_branch" ]]; then
  echo "[SessionStart] Warning: Could not detect base branch for '$current_branch'." >&2
  echo "  To set manually: git config branch.${current_branch}.stop-hook-base-branch <branch>" >&2
fi

exit 0
