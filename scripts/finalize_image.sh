#!/bin/bash
set -eu -o pipefail

# Rename kiwi's raw disk image(s) to .img, optionally xz-compressing them.
# Usage: finalize_image.sh <output-dir> <compress:0|1>

echo "Executing $0 ..."

outdir=$1
compress=$2

for raw in "$outdir"/*.raw; do
	[ -e "$raw" ] || continue
	img="${raw%.raw}.img"
	mv -f "$raw" "$img"
	if [ "$compress" = "1" ]; then
		echo "Compressing image $img to .xz ..."
		xz -v -T0 -k -f "$img"
	fi
done

echo "Finished executing $0 ."
