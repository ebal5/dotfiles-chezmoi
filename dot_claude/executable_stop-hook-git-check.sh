#!/bin/bash

# Stop hook: Check for uncommitted/unpushed changes before session ends
#
# Exit codes:
#   0 - OK, session can stop
#   2 - Block session stop (uncommitted changes, untracked files, or unpushed commits)

# Read the JSON input from stdin
input=$(cat)

# Check if stop hook is already active (recursion prevention)
stop_hook_active=$(echo "$input" | jq -r '.stop_hook_active')
if [[ "$stop_hook_active" = "true" ]]; then
  exit 0
fi

# Check if we're in a git repository - bail if not
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  exit 0
fi

# Check for uncommitted changes (both staged and unstaged)
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "There are uncommitted changes in the repository. Please commit and push these changes to the remote branch." >&2
  exit 2
fi

# Check for untracked files that might be important
untracked_files=$(git ls-files --others --exclude-standard)
if [[ -n "$untracked_files" ]]; then
  echo "There are untracked files in the repository. Please commit and push these changes to the remote branch." >&2
  exit 2
fi

current_branch=$(git branch --show-current)
if [[ -n "$current_branch" ]]; then
  if git rev-parse "origin/$current_branch" >/dev/null 2>&1; then
    # Branch exists on remote - compare against it
    unpushed=$(git rev-list "origin/$current_branch..HEAD" --count 2>/dev/null) || unpushed=0
    if [[ "$unpushed" -gt 0 ]]; then
      echo "There are $unpushed unpushed commit(s) on branch '$current_branch'. Please push these changes to the remote repository." >&2
      exit 2
    fi
  else
    # Branch doesn't exist on remote - determine base branch for comparison
    # Priority: 1. env var, 2. branch-specific git config, 3. repo-wide git config, 4. origin/HEAD
    base_branch=""
    if [[ -n "${CLAUDE_STOP_HOOK_BASE_BRANCH:-}" ]]; then
      base_branch="$CLAUDE_STOP_HOOK_BASE_BRANCH"
    elif base_branch=$(git config "branch.${current_branch}.stop-hook-base-branch" 2>/dev/null) && [[ -n "$base_branch" ]]; then
      : # base_branch already set
    elif base_branch=$(git config "stop-hook.base-branch" 2>/dev/null) && [[ -n "$base_branch" ]]; then
      : # base_branch already set
    else
      base_branch="origin/HEAD"
    fi

    # Validate the base branch exists
    if ! git rev-parse "$base_branch" >/dev/null 2>&1; then
      echo "Warning: Configured base branch '$base_branch' does not exist. Skipping unpushed check." >&2
      exit 0
    fi

    unpushed=$(git rev-list "${base_branch}..HEAD" --count 2>/dev/null) || unpushed=0
    if [[ "$unpushed" -gt 0 ]]; then
      echo "Branch '$current_branch' has $unpushed unpushed commit(s) compared to '$base_branch'. Please push these changes to the remote repository." >&2
      exit 2
    fi
  fi
fi

exit 0
