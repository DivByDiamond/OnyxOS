#!/usr/bin/env python3
"""Build and stage the onyxdesk daemon plus its default desk.conf."""
import argparse
from pathlib import Path, PurePosixPath
import shutil
import struct
import subprocess


def validate_desk(path):
    data = path.read_bytes()
    if len(data) < 344 or data[:4] != b"ONX1":
        raise ValueError(f"Invalid ONX1 desk daemon: {path}")
    version, entry, count, flags = struct.unpack_from("<IQII", data, 4)
    if version != 1 or not 1 <= count <= 8 or not flags & 2:
        raise ValueError("Desk daemon must be ONX v1 with ring 1 execution flag")
    executable_entry = False
    for index in range(count):
        address, size, memory, offset, permissions = struct.unpack_from(
            "<QQQII", data, 24 + 40 * index)
        if size > memory or offset + size > len(data):
            raise ValueError("Desk daemon has an invalid ONX segment")
        if permissions & 8 and address <= entry < address + memory:
            executable_entry = True
    if not executable_entry:
        raise ValueError("Desk daemon entry is outside executable segments")


def package(repos, output, manifest):
    desk = repos / "OnyxDesktop"
    conf = desk / "etc/desk.conf"
    required = (desk / "Makefile", desk / "src/main.c", conf)
    if not all(path.is_file() for path in required):
        raise ValueError(f"Incomplete desktop repository: {desk}")
    output.mkdir(parents=True, exist_ok=True)
    stage = output / "desktop"
    if any(character.isspace() for character in str(stage)):
        raise ValueError("OnyxFS manifest host paths cannot contain whitespace")
    # Same incremental make the build pipeline runs: a fresh checkout
    # compiles here, an already-built one no-ops instantly.
    subprocess.run(["make", "-C", str(desk), "ONYXCC=" + str(repos / "OnyxCompiller/onyxcc"),
                    "build/onyxdesk.onx"], check=True)
    artifact = desk / "build/onyxdesk.onx"
    validate_desk(artifact)
    resources = [(artifact, "/bin/onyxdesk"), (conf, "/etc/desk.conf")]
    staged = []
    for source, target in resources:
        destination = stage / target.lstrip("/")
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)
        staged.append((destination, target))
    targets = {target for _, target in staged}
    lines = manifest.read_text().splitlines()
    # Repackaging replaces these destinations so /bin/onyxdesk and
    # /etc/desk.conf are installed exactly once each.
    lines = [line for line in lines
             if not (line.startswith("file ") and line.rsplit(" ", 1)[-1] in targets)]
    directories = {str(parent) for target in targets
                   for parent in PurePosixPath(target).parents if str(parent) != "/"}
    lines.extend(f"dir {directory}" for directory in sorted(
        directories, key=lambda value: (value.count("/"), value))
        if f"dir {directory}" not in lines)
    lines.extend(f"file {source} {target}" for source, target in staged)
    manifest.write_text("\n".join(lines) + "\n")
    print("Packaged /bin/onyxdesk and /etc/desk.conf")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repos", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("manifest", type=Path)
    args = parser.parse_args()
    package(args.repos.resolve(), args.output.resolve(), args.manifest.resolve())
