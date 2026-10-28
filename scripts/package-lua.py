#!/usr/bin/env python3
"""Add Lua documentation, example and self-test when Lua is in this image."""
import argparse
from pathlib import Path


def package(repos, manifest):
    lines = manifest.read_text().splitlines()
    if not any(line.startswith("file ") and line.endswith(" /bin/lua") for line in lines):
        return
    root = repos / "OnyxApps/apps/lua"
    directories = ("/usr", "/usr/share", "/usr/share/lua", "/usr/share/lua/5.5",
                   "/usr/share/doc", "/usr/share/doc/lua")
    resources = (("README.md", "/usr/share/doc/lua/README.md"),
                 ("vendor/LICENSE.txt", "/usr/share/doc/lua/LICENSE.txt"),
                 ("examples/hello.lua", "/usr/share/lua/5.5/hello.lua"),
                 ("tests/runtime.lua", "/usr/share/lua/5.5/selftest.lua"))
    for relative, _ in resources:
        if not (root / relative).is_file():
            raise ValueError(f"Missing Lua resource: {root / relative}")
    additions = [f"dir {directory}" for directory in directories
                 if f"dir {directory}" not in lines]
    additions.extend(f"file {root / relative} {target}" for relative, target in resources)
    with manifest.open("a") as stream:
        stream.write("\n".join(additions) + "\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repos", type=Path)
    parser.add_argument("manifest", type=Path)
    args = parser.parse_args()
    package(args.repos.resolve(), args.manifest.resolve())
