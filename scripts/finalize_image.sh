#!/bin/sh
set -eu

# Rename kiwi's raw disk image(s) to .img, optionally xz-compressing them.
# Usage: finalize_image.sh <output-dir> <compress:0|1> <platform> <distro> <release> <arch> <tier> <version>
# Renames to "<platform>_<distro>-<release>-<arch>-<tier>_<version>.img".

echo "Executing $0 ..."

outdir=$1
compress=$2
platform=$3
distro=$4
release=$5
arch=$6
tier=$7
version=$8

for raw in "$outdir"/*.raw; do
	[ -e "$raw" ] || continue
	img="$outdir/${platform}_${distro}-${release}-${arch}-${tier}_${version}.img"
	mv -f "$raw" "$img"
	if [ "$compress" = "1" ]; then
		echo "Compressing image $img to .xz ..."
		xz -v -T0 -k -f "$img"
	fi
done

echo "Finished executing $0 ."
