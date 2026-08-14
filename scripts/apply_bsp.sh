#!/bin/sh
set -eu

# Merge bsp/$device/common with bsp/$device/$distribution/{$release,latest}
# into a top-level overlay dir kiwi's profile-overlay discovery can find.
# Never fails the build.

echo "Executing $0 ..."

bsp_dir=bsp
device=
distribution=
release=
target=

while [ $# -gt 0 ]; do
	case $1 in
	--bsp-dir)
		bsp_dir=$2
		shift 2
		;;
	--device)
		device=$2
		shift 2
		;;
	--distribution)
		distribution=$2
		shift 2
		;;
	--release)
		release=$2
		shift 2
		;;
	--target)
		target=$2
		shift 2
		;;
	*)
		echo "Unknown argument: $1" >&2
		exit 1
		;;
	esac
done

[ -n "$device" ] || {
	echo "ERROR: --device is required" >&2
	exit 1
}
[ -n "$distribution" ] || {
	echo "ERROR: --distribution is required" >&2
	exit 1
}
[ -n "$release" ] || {
	echo "ERROR: --release is required" >&2
	exit 1
}
[ -n "$target" ] || target=$device

# Merge src into dst, preserving symlinks and skipping paths dst already has.
#
# Checking for a symlink before checking for a directory
# avoids collisions and dereferencing.
merge_tree() (
	src=$1
	dst=$2
	mkdir -p "$dst"
	for entry in "$src"/* "$src"/.[!.]* "$src"/..?*; do
		if [ -L "$entry" ]; then
			name=${entry##*/}
			d="$dst/$name"
			if [ -e "$d" ] || [ -L "$d" ]; then
				continue
			fi
			ln -s "$(readlink "$entry")" "$d"
		elif [ -e "$entry" ]; then
			name=${entry##*/}
			d="$dst/$name"
			if [ -d "$entry" ]; then
				merge_tree "$entry" "$d"
			else
				cp -p "$entry" "$d"
			fi
		fi
	done
)

device_dir="$bsp_dir/$device"
common_dir="$device_dir/common"
release_dir="$device_dir/$distribution/$release"
latest_dir="$device_dir/$distribution/latest"
# $release takes priority over latest; never both.
if [ -d "$release_dir" ]; then
	distro_dir=$release_dir
else
	distro_dir=$latest_dir
fi

if [ -e "$target" ]; then
	rm -rf "$target"
fi

found=0
for layer in "$common_dir" "$distro_dir"; do
	if [ -d "$layer" ]; then
		# Merges layers: files overwrite matching paths, but a symlink
		# (e.g. usrmerge's lib -> usr/lib) is only created if nothing
		# already occupies that path, and existing symlinks are followed
		# rather than replaced.
		merge_tree "$layer" "$target"
		found=1
	fi
done

if [ "$found" -eq 0 ]; then
	echo "NOTE: this platform does not have specific configurations."
fi

echo "Finished executing $0 ."
