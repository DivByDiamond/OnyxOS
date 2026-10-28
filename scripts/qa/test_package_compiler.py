"""Compiler image resources preserve relative includes used by libc."""
import importlib.util
from pathlib import Path
import struct
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "package-compiler.py"
spec = importlib.util.spec_from_file_location("package_compiler", SCRIPT)
packaging = importlib.util.module_from_spec(spec)
spec.loader.exec_module(packaging)


class CompilerPackagingTest(unittest.TestCase):
    def test_library_relative_include_dependencies_are_staged(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            compiler = root / "repos/OnyxCompiller"
            files = {
                "libonyxc/src/core/start_cc.c": "void _start(void) {}",
                "libonyxc/src/core/syscalls.c": '#include "../../../include/sys/syscalls.h"',
                "libonyxc/src/io/stdio.c": '#include "../format/internal.h"',
                "libonyxc/src/format/internal.h": "#define ONYX_FMT_MINUS 1",
                "libonyxc/include/stdio.h": "int puts(const char *);",
                "include/sys/syscalls.h": "#define SYS_write 1",
                "LICENSE": "license",
                "README.md": "readme",
                "docs/STATUS.md": "status",
            }
            for relative, content in files.items():
                path = compiler / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content)
            binary = bytearray(345)
            binary[:4] = b"ONX1"
            struct.pack_into("<IQII", binary, 4, 1, 0x1000, 1, 2)
            struct.pack_into("<QQQII", binary, 24, 0x1000, 1, 1, 344, 8)
            (compiler / "onyxcc_self.onx").write_bytes(binary)
            manifest = root / "manifest"
            manifest.write_text("dir /bin\n")
            with patch.object(packaging.subprocess, "run"):
                packaging.package(root / "repos", root / "out", manifest)
            resources = {}
            for line in manifest.read_text().splitlines():
                if line.startswith("file "):
                    _, source, target = line.split()
                    resources[target] = Path(source)
            for source in ("/usr/onyxc/lib/src/core/syscalls.c",
                           "/usr/onyxc/lib/src/io/stdio.c"):
                include = resources[source].read_text().split('"')[1]
                target = (resources[source].parent / include).resolve()
                self.assertTrue(target.is_file(), str(target))
                self.assertIn(target, [path.resolve() for path in resources.values()])


if __name__ == "__main__":
    unittest.main()
