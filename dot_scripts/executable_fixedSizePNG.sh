#!/usr/bin/env bash
set -euo pipefail

# thanks to https://hostingstock.net/blog/20160206/

# Check dependencies
check_dependencies() {
  local deps=("$@")
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      echo "Error: $dep is required but not installed." >&2
      exit 1
    fi
  done
}

# Initialize cleanup
extra_text_fn=""
cleanup() {
  [[ -n "$extra_text_fn" && -f "$extra_text_fn" ]] && rm -f "$extra_text_fn" 2>/dev/null || true
}
trap cleanup EXIT

get_random_text() {
  local length="$1"
  if [[ ! "$length" =~ ^[0-9]+$ ]] || [[ "$length" -le 0 ]]; then
    echo "Error: Invalid text length specified." >&2
    return 1
  fi
  LC_CTYPE=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1
}

# Validate arguments
if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <target_size> [output_filename]" >&2
  echo "Example: $0 1024 myimage.png" >&2
  exit 1
fi

if ! [[ "$1" =~ ^[0-9]+$ ]] || [[ "$1" -le 0 ]]; then
  echo "Error: Target size must be a positive integer." >&2
  exit 1
fi

# Check required commands
check_dependencies convert exiftool hexdump mktemp wc fold tr head

target_size=$1
img_name=${2:-output.png}

img_size="640x640"
text_length=20
hex_color=$(hexdump -n 3 -v -e '"" 3/1 "%02X" "\n"' /dev/urandom)
text=$(get_random_text $text_length)

# フォントはどうでもいい
convert -size "${img_size}" "xc:#${hex_color}" \
  -gravity Center -pointsize 72 -annotate 0 "640x640" \
  -gravity Center -pointsize 16 -annotate "+0+80" "$text" \
  "$img_name"

img_file_size=$(wc -c <"$img_name")
extra_text_size=$((target_size - 21 - img_file_size))

if [[ ${extra_text_size} -lt 1 ]]; then
  echo "Error: Target size too small for generated image." >&2
  rm "$img_name"
  exit 1
fi

extra_text_fn=$(mktemp) && chmod 600 "$extra_text_fn"
get_random_text $extra_text_size >"$extra_text_fn"

exiftool -ignoreMinorErrors -overwrite_original "$img_name" -comment\<="$extra_text_fn" >/dev/null
