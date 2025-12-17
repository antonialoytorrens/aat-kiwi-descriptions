#!/usr/bin/env python3
import xml.etree.ElementTree as ET
import unittest
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

class TestXmlLint(unittest.TestCase):

    def test_xml_syntax(self):
        """Validates syntax of all XML files in the repository."""
        # Find all XML files recursively, excluding build directories
        xml_files = [f for f in BASE_DIR.rglob("*.xml") if "build" not in f.parts]
        
        print(f"\n[TEST] Checking {len(xml_files)} XML files for syntax errors...")
        error_count = 0
        for xml_file in xml_files:
            try:
                ET.parse(xml_file)
            except ET.ParseError as e:
                print(f"  [ERROR] {xml_file.relative_to(BASE_DIR)}: {e}")
                error_count += 1
        
        self.assertEqual(error_count, 0, f"Found {error_count} XML syntax errors.")

if __name__ == '__main__':
    unittest.main()
