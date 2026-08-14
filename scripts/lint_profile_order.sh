#!/bin/sh
set -eu

# Lint XML ordering conventions:
# - components/*/*.xml: common_* profile blocks must come first, followed by
#   device-specific blocks in alphabetical order.
# - <include from="..."> entries pointing into components/ or platforms/ (e.g.
#   in config.xml) must each be in alphabetical order among their own group.

# Deterministic byte-wise ordering, matching Python's default ordinal string
# comparison (locale collation could otherwise reorder sort/awk comparisons).
export LC_ALL=C

echo "Executing $0 ..."

if [ $# -eq 0 ]; then
	echo "usage: $0 file.xml [file.xml ...]" >&2
	exit 1
fi

# common_* blocks must precede device-specific blocks, and device-specific
# blocks (keyed by the alphabetically-smallest name in a comma-list) must be
# in alphabetical order.
check_profile_order() {
	f=$1
	xmllint --xpath '/*/*[self::packages or self::preferences][@profiles]/@profiles' "$f" 2>/dev/null \
		| sed -n 's/^ profiles="\(.*\)"$/\1/p' \
		| awk -v path="$f" -v q="'" '
			{
				profiles_attr = $0
				n = split(profiles_attr, names, ",")
				is_common = 1
				key = ""
				for (i = 1; i <= n; i++) {
					name = names[i]
					gsub(/^[ \t]+|[ \t]+$/, "", name)
					if (substr(name, 1, 7) != "common_") is_common = 0
					if (key == "" || name < key) key = name
				}
				if (is_common) {
					if (seen_device_block) {
						printf "ERROR: %s: common_* block %s%s%s must come before device-specific blocks, not after\n", path, q, profiles_attr, q
						err = 1
					}
					next
				}
				seen_device_block = 1
				if (prev_key != "" && key < prev_key) {
					printf "ERROR: %s: block %s%s%s (sorts as %s%s%s) is out of alphabetical order - it comes after %s%s%s\n", path, q, profiles_attr, q, q, key, q, q, prev_key, q
					err = 1
				}
				prev_key = key
			}
			END { exit err }
		'
}

# <include from="..."> entries pointing into components/ or platforms/ must be
# in alphabetical order among their own group, ordered by parent folder then
# file (a raw string compare can disagree with that, e.g. "." sorts before "/"
# in ASCII, so a "/" in the sort key is replaced with a lower byte to make a
# plain byte-string sort match folder-then-file order).
check_include_order() {
	f=$1
	xmllint --xpath '//include/@from' "$f" 2>/dev/null \
		| sed -n 's/^ from="\(.*\)"$/\1/p' \
		| awk -v path="$f" -v q="'" '
			function sentinel_key(s,   r) {
				r = s
				gsub(/\//, "\001", r)
				return r
			}
			function check_one(src, marker, label,   pos, rest, key, n, i) {
				pos = index(src, marker)
				if (pos == 0) return
				rest = substr(src, pos + length(marker))
				key = sentinel_key(rest)
				n = ++count[label]
				i = n
				while (i > 1 && sorted_key[label, i - 1] > key) {
					sorted_key[label, i] = sorted_key[label, i - 1]
					sorted_val[label, i] = sorted_val[label, i - 1]
					i--
				}
				sorted_key[label, i] = key
				sorted_val[label, i] = src
				orig_val[label, n] = src
			}
			{
				check_one($0, "/components/", "components")
				check_one($0, "/platforms/", "platforms")
			}
			END {
				err = 0
				for (i = 1; i <= count["components"]; i++) {
					if (orig_val["components", i] != sorted_val["components", i]) {
						printf "ERROR: %s: <include from=\"%s\"> is out of order among components/ includes (ordered by parent folder, then file) - expected %s%s%s at this position\n", path, orig_val["components", i], q, sorted_val["components", i], q
						err = 1
						break
					}
				}
				for (i = 1; i <= count["platforms"]; i++) {
					if (orig_val["platforms", i] != sorted_val["platforms", i]) {
						printf "ERROR: %s: <include from=\"%s\"> is out of order among platforms/ includes (ordered by parent folder, then file) - expected %s%s%s at this position\n", path, orig_val["platforms", i], q, sorted_val["platforms", i], q
						err = 1
						break
					}
				}
				exit err
			}
		'
}

errors_found=0
for f in "$@"; do
	# Match Python's pathlib, which collapses a leading "./" in path display.
	f=${f#./}
	if ! check_profile_order "$f" >&2; then
		errors_found=1
	fi
	if ! check_include_order "$f" >&2; then
		errors_found=1
	fi
done

echo "Finished executing $0 ."

exit "$errors_found"
