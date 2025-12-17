#!/usr/bin/env python3
import subprocess
import unittest
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

class TestKiwiConfig(unittest.TestCase):

    def test_kiwi_config(self):
        """Validates Kiwi configuration using kiwi-ng."""
        print("\n[TEST] Validating Kiwi configuration schema...")
        
        # Run kiwi-ng image info validation
        # Requires kiwi-ng to be installed and in PATH
        result = subprocess.run(
            ["kiwi-ng", "image", "info", "--description", str(BASE_DIR)],
            capture_output=True,
            text=True
        )
        
        if result.returncode != 0:
            print(f"  [ERROR] Kiwi validation failed:\n{result.stderr}")
            if "KiwiDescriptionInvalid" in result.stderr:
                 self.fail("Kiwi schema validation failed. Run 'kiwi-ng image info --debug --description .' for details.")
            else:
                 self.fail(f"Kiwi command failed: {result.stderr}")

if __name__ == '__main__':
    unittest.main()
