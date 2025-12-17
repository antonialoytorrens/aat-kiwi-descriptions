#!/usr/bin/env python3
import subprocess
import unittest
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent


class TestShellCheck(unittest.TestCase):

    def test_shell_scripts(self) -> None:
        """Lints shell scripts using shellcheck."""
        scripts = [
            BASE_DIR / "config.sh",
            BASE_DIR / "editbootinstall",
            BASE_DIR / "post_bootstrap.sh",
            BASE_DIR / "pre_disk_sync.sh",
        ]
        # Filter existing only
        scripts = [s for s in scripts if s.exists()]

        print(f"\n[TEST] Linting {len(scripts)} shell scripts...")

        for script in scripts:
            rel_path = script.relative_to(BASE_DIR)
            result = subprocess.run(
                ["shellcheck", str(script)], capture_output=True, text=True, check=False
            )
            if result.returncode != 0:
                print(f"  [ERROR] Shellcheck issues in {rel_path}:\n{result.stdout.strip()}")
                self.fail(f"Shellcheck failed for {rel_path}")


if __name__ == "__main__":
    unittest.main()
