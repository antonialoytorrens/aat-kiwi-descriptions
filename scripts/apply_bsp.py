#!/usr/bin/env python3
"""Merge bsp/$device/common with bsp/$device/$distribution/{$release,latest}
into a top-level overlay dir kiwi's profile-overlay discovery can find.
Never fails the build."""
import argparse
import os
import shutil
import sys
from pathlib import Path


def merge_tree(src: Path, dst: Path) -> None:
    """Merge src into dst, preserving symlinks and skipping paths dst already has.

    Plain shutil.copytree either dereferences symlinks into duplicated real
    directories, or (with symlinks=True) crashes if a later layer's symlink
    collides with a real directory an earlier layer already created (e.g.
    usrmerge's lib -> usr/lib). Recursing by hand avoids both.
    """
    dst.mkdir(parents=True, exist_ok=True)
    for entry in src.iterdir():
        d = dst / entry.name
        if entry.is_symlink():
            if d.exists() or d.is_symlink():
                continue
            d.symlink_to(os.readlink(entry))
        elif entry.is_dir():
            merge_tree(entry, d)
        else:
            shutil.copy2(entry, d)


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
            # Merges layers: files overwrite matching paths, but a symlink
            # (e.g. usrmerge's lib -> usr/lib) is only created if nothing
            # already occupies that path, and existing symlinks are followed
            # rather than replaced.
            merge_tree(layer, target)
            found = True

    if not found:
        print("NOTE: this platform does not have specific configurations.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
