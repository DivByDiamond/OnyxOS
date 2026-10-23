"""Verify stale app products cannot enter a newly built image's input list."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location(
    "build_apps", Path(__file__).resolve().parents[1] / "build-apps.py"
)
build_apps = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(build_apps)


class AppStagingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.app = self.root / "OnyxApps/apps/demo"
        self.app.mkdir(parents=True)
        self.source = self.app / "main.c"
        self.source.write_text("new source")
        compiler = self.root / "OnyxCompiller/onyxcc"
        compiler.parent.mkdir()
        compiler.write_text('''#!/usr/bin/env python3
import sys
from pathlib import Path
source = Path(sys.argv[-1]).read_text()
if source == "broken":
    sys.exit(1)
Path(sys.argv[sys.argv.index("-o") + 1]).write_text(source)
''')
        compiler.chmod(0o755)
        self.output = self.root / "output"
        self.output.mkdir()
        self.listing = self.output / "apps.list"

    def test_fresh_stage_ignores_stale_files_and_rebuilds_after_source_change(self):
        stale = self.output / "stale.onx"
        stale.write_text("old application")
        first = build_apps.build(self.root, self.output, self.listing)[0]
        self.source.write_text("updated source")
        second = build_apps.build(self.root, self.output, self.listing)[0]
        self.assertNotEqual(first, second)
        self.assertEqual(second.read_text(), "updated source")
        self.assertEqual(first.read_text(), "new source")
        self.assertEqual(stale.read_text(), "old application")
        self.assertEqual(self.listing.read_text(), str(second) + "\n")

    def test_compile_failure_cannot_publish_partial_or_stale_list(self):
        product = build_apps.build(self.root, self.output, self.listing)[0]
        self.source.write_text("broken")
        with self.assertRaises(subprocess.CalledProcessError):
            build_apps.build(self.root, self.output, self.listing)
        self.assertEqual(self.listing.read_text(), str(product) + "\n")


if __name__ == "__main__":
    unittest.main()
