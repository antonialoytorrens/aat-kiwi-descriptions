#!/bin/bash
set -eu -o pipefail

echo "Executing $0 ..."

# Remove kiwi leftovers we don't need
# https://github.com/OSInside/kiwi/issues/2343#issuecomment-1663427508
rm -rf /boot/mbrid /config.bootoptions /config.partids

## Create /etc/X11/xorg.conf.d, see rhbz#2240159
#mkdir -p /etc/X11/xorg.conf.d

echo "Finished executing $0 ."

exit 0
