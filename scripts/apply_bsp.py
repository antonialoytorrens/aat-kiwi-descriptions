#!/usr/bin/env python3
"""Merge bsp/$device/common with bsp/$device/$distribution/{$release,latest}
into a top-level overlay dir kiwi's profile-overlay discovery can find.
Never fails the build."""
import argparse
import shutil
import sys
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--bsp-dir", default="bsp")
    parser.add_argument("--device", required=True)
    parser.add_argument("--distribution", required=True)
    parser.add_argument("--release", required=True)
    parser.add_argument("--target")
    args = parser.parse_args()

    target = Path(args.target or args.device)
    device_dir = Path(args.bsp_dir) / args.device
    common_dir = device_dir / "common"
    release_dir = device_dir / args.distribution / args.release
    latest_dir = device_dir / args.distribution / "latest"
    # $release takes priority over latest; never both.
    distro_dir = release_dir if release_dir.is_dir() else latest_dir

    found = False
    if target.exists():
        shutil.rmtree(target)

    for layer in (common_dir, distro_dir):
        if layer.is_dir():
            # dirs_exist_ok merges layers, later ones overwriting matching paths.
            shutil.copytree(layer, target, dirs_exist_ok=True)
            found = True

    if not found:
        print("NOTE: this platform does not have specific configurations.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
