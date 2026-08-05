#!/usr/bin/env python3
"""Lint XML ordering conventions:
- components/*/*.xml: common_* profile blocks must come first, followed by
  device-specific blocks in alphabetical order.
- <include from="..."> entries pointing into components/ or platforms/ (e.g.
  in config.xml) must each be in alphabetical order among their own group."""
import argparse
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def block_key(profiles_attr: str) -> str:
    return min(name.strip() for name in profiles_attr.split(","))


def is_common(profiles_attr: str) -> bool:
    return all(name.strip().startswith("common_") for name in profiles_attr.split(","))


def check_profile_order(path: Path, root: ET.Element) -> list[str]:
    errors = []
    seen_device_block = False
    prev_key = None

    for child in root:
        if child.tag not in ("packages", "preferences"):
            continue
        profiles_attr = child.get("profiles")
        if not profiles_attr:
            continue

        if is_common(profiles_attr):
            if seen_device_block:
                errors.append(
                    f"{path}: common_* block '{profiles_attr}' must come "
                    "before device-specific blocks, not after"
                )
            continue

        seen_device_block = True
        key = block_key(profiles_attr)
        if prev_key is not None and key < prev_key:
            errors.append(
                f"{path}: block '{profiles_attr}' (sorts as '{key}') is out "
                f"of alphabetical order - it comes after '{prev_key}'"
            )
        prev_key = key

    return errors


def include_sort_key(src: str, marker: str) -> tuple[str, ...]:
    # Order by path segment after the category marker: parent folder(s)
    # first, then the file itself - e.g. components/$distro/$file.xml sorts
    # by $distro, then by $file, rather than comparing the raw path string
    # (which can disagree with folder-then-file ordering, e.g. "." sorts
    # before "/" in ASCII).
    rest = src[src.index(marker) + len(marker):]
    return tuple(rest.split("/"))


def check_include_order(path: Path, root: ET.Element) -> list[str]:
    errors = []
    for category in ("components", "platforms"):
        marker = f"/{category}/"
        includes = [
            src
            for child in root.iter("include")
            for src in [child.get("from", "")]
            if marker in src
        ]
        sorted_includes = sorted(includes, key=lambda src: include_sort_key(src, marker))
        if includes != sorted_includes:
            for actual, expected in zip(includes, sorted_includes):
                if actual != expected:
                    errors.append(
                        f"{path}: <include from=\"{actual}\"> is out of order "
                        f"among {category}/ includes (ordered by parent "
                        f"folder, then file) - expected '{expected}' at this "
                        "position"
                    )
                    break

    return errors


def check_file(path: Path) -> list[str]:
    root = ET.parse(path).getroot()
    return check_profile_order(path, root) + check_include_order(path, root)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("files", nargs="+", type=Path)
    args = parser.parse_args()

    errors = []
    for path in args.files:
        errors.extend(check_file(path))

    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
