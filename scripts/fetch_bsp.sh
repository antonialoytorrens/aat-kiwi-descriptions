#!/bin/sh
set -eu

# Clone or update the bsp (board support) repo. Never fails the build.

echo "Executing $0 ..."

repo=
branch=main
dest=bsp

while [ $# -gt 0 ]; do
	case $1 in
	--repo)
		repo=$2
		shift 2
		;;
	--branch)
		branch=$2
		shift 2
		;;
	--dest)
		dest=$2
		shift 2
		;;
	*)
		echo "Unknown argument: $1" >&2
		exit 1
		;;
	esac
done

[ -n "$repo" ] || {
	echo "ERROR: --repo is required" >&2
	exit 1
}

# Avoid hanging on an unreachable/interactive host.
GIT_TERMINAL_PROMPT=0
GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=10"
export GIT_TERMINAL_PROMPT GIT_SSH_COMMAND

if [ -d "$dest/.git" ]; then
	echo "Updating bsp repository..."
	if ! git -C "$dest" pull -qq --ff-only origin "$branch"; then
		echo "WARNING: could not fetch bsp ($repo)" >&2
	fi
else
	echo "Cloning bsp repository..."
	if ! git clone -qq --branch "$branch" "$repo" "$dest"; then
		echo "WARNING: could not fetch bsp ($repo)" >&2
	fi
fi

echo "Finished executing $0 ."

exit 0
