#!/usr/bin/env python3
"""Rebuild and stage the executable compiler, C library sources and docs."""
import argparse
from pathlib import Path, PurePosixPath
import shutil
import struct
import subprocess


def validate_compiler(path):
    data = path.read_bytes()
    if len(data) < 344 or data[:4] != b"ONX1":
        raise ValueError(f"Invalid ONX1 compiler: {path}")
    version, entry, count, flags = struct.unpack_from("<IQII", data, 4)
    if version != 1 or not 1 <= count <= 8 or not flags & 2:
        raise ValueError("Compiler must be ONX v1 with root execution flag")
    executable_entry = False
    for index in range(count):
        address, size, memory, offset, permissions = struct.unpack_from(
            "<QQQII", data, 24 + 40 * index)
        if size > memory or offset + size > len(data):
            raise ValueError("Compiler has an invalid ONX segment")
        if permissions & 8 and address <= entry < address + memory:
            executable_entry = True
    if not executable_entry:
        raise ValueError("Compiler entry is outside executable segments")


def package(repos, output, manifest):
    compiler = repos / "OnyxCompiller"
    library = compiler / "libonyxc"
    required = (library / "src/core/start_cc.c", compiler / "LICENSE",
                compiler / "README.md")
    if not all(path.is_file() for path in required):
        raise ValueError(f"Incomplete compiler repository: {compiler}")
    output.mkdir(parents=True, exist_ok=True)
    stage = output / "compiler"
    if any(character.isspace() for character in str(stage)):
        raise ValueError("OnyxFS manifest host paths cannot contain whitespace")
    subprocess.run(["make", "-C", str(compiler), "selfhost"], check=True)
    artifact = compiler / "onyxcc_self.onx"
    validate_compiler(artifact)
    resources = [(artifact, "/bin/onyxcc")]
    for folder, extension in (("include", "*.h"), ("src", "*.c"), ("src", "*.h")):
        resources.extend((source, "/usr/onyxc/lib/" + source.relative_to(library).as_posix())
                         for source in sorted((library / folder).rglob(extension))
                         if source.is_file())
    resources.append((compiler / "include/sys/syscalls.h",
                      "/usr/onyxc/include/sys/syscalls.h"))
    resources.extend(((compiler / "LICENSE", "/usr/share/doc/onyxcc/LICENSE"),
                      (compiler / "README.md", "/usr/share/doc/onyxcc/README.md"),
                      (compiler / "docs/STATUS.md", "/usr/share/doc/onyxcc/STATUS.md"),
                      (Path(__file__).resolve().parents[1] / "docs/dev/compiler.md",
                       "/usr/share/doc/onyxcc/compiler.md")))
    staged = []
    for source, target in resources:
        destination = stage / target.lstrip("/")
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        staged.append((destination, target))
    example = stage / "usr/share/onyxcc/hello.c"
    example.parent.mkdir(parents=True, exist_ok=True)
    example.write_text('#include <stdio.h>\nint main(void) {\n'
                       '    printf("Hello from OnyxCC!\\n");\n    return 0;\n}\n')
    staged.append((example, "/usr/share/onyxcc/hello.c"))
    targets = {target for _, target in staged}
    lines = manifest.read_text().splitlines()
    # Repackaging replaces these destinations, including any stale compiler
    # app entry, so /bin/onyxcc is installed exactly once.
    lines = [line for line in lines
             if not (line.startswith("file ") and line.rsplit(" ", 1)[-1] in targets)]
    directories = {str(parent) for target in targets
                   for parent in PurePosixPath(target).parents if str(parent) != "/"}
    lines.extend(f"dir {directory}" for directory in sorted(
        directories, key=lambda value: (value.count("/"), value))
        if f"dir {directory}" not in lines)
    lines.extend(f"file {source} {target}" for source, target in staged)
    manifest.write_text("\n".join(lines) + "\n")
    print(f"Packaged /bin/onyxcc and {len(staged) - 1} library/documentation files")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repos", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("manifest", type=Path)
    args = parser.parse_args()
    package(args.repos.resolve(), args.output.resolve(), args.manifest.resolve())
