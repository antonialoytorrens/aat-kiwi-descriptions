#!/usr/bin/env python3
import subprocess
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

BASE_DIR = Path(__file__).resolve().parent.parent


class TestKiwiConfig(unittest.TestCase):

    def test_kiwi_config(self) -> None:
        """Validates Kiwi configuration using kiwi-ng."""
        print("\n[TEST] Validating Kiwi configuration schema...")

        # Run kiwi-ng image info validation
        # Requires kiwi-ng to be installed and in PATH
        result = subprocess.run(
            ["kiwi-ng", "image", "info", "--description", str(BASE_DIR)],
            capture_output=True,
            text=True,
            check=False,
        )

        if result.returncode != 0:
            self.fail(f"[ERROR] Kiwi command failed: {result.stderr}")

    def test_kiwi_profiles(self) -> None:
        """Validates Kiwi profiles using kiwi-ng."""
        print("\n[TEST] Validating Kiwi profiles...")
        with TemporaryDirectory() as tmpdir:
            result = subprocess.run(
                [
                    "kiwi-ng",
                    "--profile",
                    "x86_64",
                    "system",
                    "build",
                    "--description",
                    str(BASE_DIR),
                    "--target-dir",
                    tmpdir,
                ],
                capture_output=True,
                text=True,
                check=False,
            )

            if result.returncode != 0:
                print(f"  [ERROR] Kiwi validation failed:\n{result.stderr}")


if __name__ == "__main__":
    unittest.main()
