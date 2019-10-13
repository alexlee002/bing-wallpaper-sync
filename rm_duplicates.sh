#!/bin/sh

TMP_HASH="./tmp_hash"
BAK_DIR="./duplicates"

rm -f "$TMP_HASH"
touch "$TMP_HASH"

for f in "$1"/*.jpg; do
	[[ -L "$f" ]] && continue

	hash="$( md5 "$f" | awk -F "=" '{print $2}' | awk '{$1=$1};1')"
	count="$( grep -a "$hash" "$TMP_HASH" | wc -l )"

	[ $count -gt 0 ] && mkdir -p "$BAK_DIR" && mv -f "$f" "$BAK_DIR/" && echo "$hash $count"
	echo $hash >> "$TMP_HASH"
done

rm -f "$TMP_HASH"
