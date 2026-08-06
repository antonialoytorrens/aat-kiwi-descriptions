#!/usr/bin/env python3
"""Clone or update the bsp (board support) repo. Never fails the build."""
import argparse
import os
import subprocess
import sys
from pathlib import Path

# Avoid hanging on an unreachable/interactive host.
GIT_ENV = {
    **os.environ,
    "GIT_TERMINAL_PROMPT": "0",
    "GIT_SSH_COMMAND": "ssh -o BatchMode=yes -o ConnectTimeout=10",
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", required=True)
    parser.add_argument("--branch", default="main")
    parser.add_argument("--dest", default="bsp")
    args = parser.parse_args()

    dest = Path(args.dest)
    try:
        if (dest / ".git").is_dir():
            print("Updating bsp repository...")
            subprocess.run(
                ["git", "-C", str(dest), "pull", "-qq", "--ff-only", "origin", args.branch],
                check=True, env=GIT_ENV,
            )
        else:
            print("Cloning bsp repository...")
            subprocess.run(
                ["git", "clone", "-qq", "--branch", args.branch, args.repo, str(dest)],
                check=True, env=GIT_ENV,
            )
    except (subprocess.CalledProcessError, OSError) as error:
        print(f"WARNING: could not fetch bsp ({args.repo}): {error}", file=sys.stderr)

    return 0


if __name__ == "__main__":
    sys.exit(main())
