#!/usr/bin/env bash

# thanks to https://hostingstock.net/blog/20160206/

check() {
  if ! convert --version >/dev/null; then
    echo "Need to install Imagemagick"
    exit 1
  fi
  if ! exiftool >/dev/null; then
    echo "Need to install exiftool"
    exit 1
  fi
}
get_random_text() {
	text=$(LC_CTYPE=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$1" | head -n 1)
	echo "$text"
}

check

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

if [ ${extra_text_size} -lt 1 ]; then
	echo too small target size
	rm "$img_name"
	exit 1
fi

extra_text_fn=$(mktemp)
get_random_text $extra_text_size >"$extra_text_fn"

exiftool -ignoreMinorErrors -overwrite_original "$img_name" -comment\<="$extra_text_fn" >/dev/null
rm "$extra_text_fn"
