#!/usr/bin/env bash
# Claude Code status line.
# Reads the status JSON on stdin (see https://code.claude.com/docs/en/statusline)
# and prints two lines:
#   line 1: user@host dir [branch]
#   line 2: model · ctx NN% · effort   (empty segments are omitted)
#
# Note: intentionally NOT using `set -e`. A status line must degrade
# gracefully — a failing git/jq call should drop a segment, not abort the
# whole line. Missing JSON fields are handled inline.
set -uo pipefail

input=$(cat)

# Single jq pass; each field is always emitted (possibly empty) so the
# tab-separated positions stay stable for `read`.
IFS=$'\t' read -r cwd model ctx effort <<EOF
$(printf '%s' "$input" | jq -r '
  [ .workspace.current_dir // ""
  , .model.display_name // ""
  , ( if (.context_window.used_percentage // null) == null
      then "" else (.context_window.used_percentage | floor | tostring) end )
  , .effort.level // ""
  ] | @tsv' 2>/dev/null)
EOF

user=$(whoami 2>/dev/null || echo "?")
host=$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo "?")
dir=$(basename "${cwd:-$PWD}")

branch=""
if [ -n "${cwd:-}" ] && cd "$cwd" 2>/dev/null; then
  b=$(git branch --show-current 2>/dev/null) || b=""
  [ -n "$b" ] && branch=" [$b]"
fi

# Line 1: identity + location
printf '%s@%s %s%s\n' "$user" "$host" "$dir" "$branch"

# Line 2: session state — skip empty segments
line2="${model:-?}"
[ -n "${ctx:-}" ] && line2="$line2 · ctx ${ctx}%"
[ -n "${effort:-}" ] && line2="$line2 · $effort"
printf '%s\n' "$line2"
