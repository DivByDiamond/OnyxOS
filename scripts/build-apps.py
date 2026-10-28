#!/usr/bin/env python3
"""Compile each source app into fresh staging; record only this run's outputs."""
import argparse
from pathlib import Path
import subprocess
import sys
import tempfile


# Apps that must run in root space (ring 1). `mux` is a terminal
# multiplexer: it owns PTY masters and execs the session shell, both of
# which the kernel only allows at ring 1. Lua/luac also need system file
# access; Lua os.execute uses the same root-only spawn interface.
ROOT_APPS = {"mux", "lua", "luac"}


def build(repos, output, listing):
    output.mkdir(parents=True, exist_ok=True)
    staging = Path(tempfile.mkdtemp(prefix="apps-", dir=output))
    compiler = repos / "OnyxCompiller/onyxcc"
    products = []
    for app in sorted((repos / "OnyxApps/apps").iterdir()):
        if not app.is_dir():
            continue
        product = staging / (app.name + ".onx")
        ring = ["--ring1"] if app.name in ROOT_APPS else []
        custom = app / "build.py"
        if custom.is_file():
            command = [sys.executable, str(custom), "--compiler", str(compiler),
                       "--output", str(product), *ring]
        else:
            sources = sorted(app.rglob("*.c"))
            if not sources:
                raise ValueError(f"No C sources for application {app.name}")
            command = [str(compiler), *ring, "-I", str(app), "-o", str(product), *map(str, sources)]
        subprocess.run(command, check=True)
        if not product.is_file():
            raise ValueError(f"Compiler did not produce {product}")
        products.append(product)
    if not products:
        raise ValueError("No applications found")
    # Replace the exact list only after every compilation succeeds.
    with tempfile.NamedTemporaryFile(mode="w", dir=listing.parent, delete=False) as stream:
        stream.write("".join(str(product) + "\n" for product in products))
        temporary = Path(stream.name)
    temporary.replace(listing)
    return products


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("repos", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("listing", type=Path)
    args = parser.parse_args()
    build(args.repos.resolve(), args.output.resolve(), args.listing.resolve())


if __name__ == "__main__":
    main()
