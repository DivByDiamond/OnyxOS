#!/usr/bin/env python3
"""Resolve exact component commits without modifying developer worktrees."""
import argparse
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def git(repo, *args):
    return subprocess.check_output(["git", "-C", str(repo), *args], text=True).strip()


def manifest(root):
    result = {}
    for line in (root / "Onyx.vent").read_text().splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        kind, url, destination = line.split()
        name = Path(destination).name
        if kind != "git" or destination != f".vent/repos/{name}" or name in result:
            raise ValueError(f"Unsupported dependency entry: {line}")
        result[name] = url
    return result


def revisions(root):
    data = json.loads((root / "Onyx.lock.json").read_text())
    if data.get("version") != 1 or set(data["revisions"]) != set(manifest(root)):
        raise ValueError("Lock must contain exactly the manifest dependencies (version 1)")
    if any(not re.fullmatch(r"[0-9a-f]{40}", sha) for sha in data["revisions"].values()):
        raise ValueError("Every dependency revision must be a full Git commit SHA")
    return data["revisions"]


def clean(repo):
    if Path(git(repo, "rev-parse", "--show-toplevel")).resolve() != repo.resolve():
        raise ValueError(f"{repo}: not a repository root")
    if git(repo, "status", "--porcelain", "--untracked-files=all"):
        raise ValueError(f"{repo}: uncommitted changes; refusing locked build or checkout")


def run(mode, root, repos):
    urls = manifest(root)
    locked = revisions(root)
    if mode == "update":
        # Validate every checkout before replacing the lock. Never record dirty trees.
        updated = {}
        for name in urls:
            repo = repos / name
            clean(repo)
            updated[name] = git(repo, "rev-parse", "HEAD")
        (root / "Onyx.lock.json").write_text(
            json.dumps({"version": 1, "revisions": updated}, indent=2) + "\n"
        )
        return
    for name, url in urls.items():
        repo = repos / name
        if mode == "workspace":
            head = git(repo, "rev-parse", "HEAD")
            dirty = bool(git(repo, "status", "--porcelain", "--untracked-files=all"))
            print(f"workspace {name}: {head}{' (dirty)' if dirty else ''}")
            continue
        if mode == "sync":
            # .vent/repos can be symlinks to active sibling repositories locally.
            if repo.is_symlink():
                raise ValueError(f"{repo}: symlink; use ONYX_DEPS_MODE=workspace for local builds")
            if not repo.exists():
                repo.parent.mkdir(parents=True, exist_ok=True)
                subprocess.run(["git", "clone", "--no-checkout", url, str(repo)], check=True)
            else:
                clean(repo)
            try:
                git(repo, "cat-file", "-e", locked[name] + "^{commit}")
            except subprocess.CalledProcessError:
                subprocess.run(["git", "-C", str(repo), "fetch", url, locked[name]], check=True)
            subprocess.run(["git", "-C", str(repo), "checkout", "--detach", locked[name]], check=True)
        clean(repo)
        if git(repo, "rev-parse", "HEAD") != locked[name]:
            raise ValueError(f"{repo}: revision differs from Onyx.lock.json; run make deps")
        print(f"locked {name}: {locked[name]}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["sync", "check", "workspace", "update"])
    parser.add_argument("--repos", type=Path, default=ROOT / ".vent/repos")
    args = parser.parse_args()
    try:
        run(args.mode, ROOT, args.repos.resolve())
    except (ValueError, KeyError, OSError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Dependency error: {error}\n")


if __name__ == "__main__":
    main()
