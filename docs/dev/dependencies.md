# Locked component revisions

`Onyx.vent` lists component URLs. `Onyx.lock.json` fixes their full Git commit
SHAs. `make deps` clones missing repositories and checks out those exact commits
under `.vent/repos/`; it does not resolve moving branch heads. Python 3 and Git
are required. Direct Vent invocation bypasses this lock.

`python3 scripts/dependencies.py check` verifies all five revisions and rejects
tracked or untracked source changes. `build-all.sh`, `build-oc2r.sh`, and release
CI check inputs before building. The release includes `Onyx.lock.json` beside
the image, so its component revisions can be inspected later.

## Updating a release

1. Commit and publish changes in each affected component repository.
2. Select the desired compatible commits in clean component checkouts.
3. Run `python3 scripts/dependencies.py update --repos /path/to/components`.
   This records committed HEADs and refuses dirty trees; it never commits or
   publishes component changes for you.
4. Review the lock diff, run `make deps` in a release checkout, build, and run
   QEMU/Sedna integration checks before committing the updated lock in OnyxOS.

The lock records selected committed component revisions. Uncommitted fixes
in developer worktrees are deliberately excluded and must be committed and
selected before a release can include them. SHA pinning alone does not guarantee
byte-identical output: host tools, Rust versions, and external firmware inputs
must also match.

## Local development

`.vent/repos/` may contain symlinks to sibling worktrees. Dependency sync refuses
to check out symlinks or dirty repositories. Use
`ONYX_DEPS_MODE=workspace bash scripts/build-all.sh` (or `build-oc2r.sh`) to build
those inputs explicitly. Workspace mode prints actual revisions and dirty state;
it is not a release verification and does not alter the lock.
In this mode `build-oc2r.sh` may include optional prebuilt `OnyxApps/build/*.onx`
files; their provenance is not verified. Locked OC2R builds rebuild the host
compiler and all applications. `build-all.sh` always compiles applications into
a fresh stage and records an exact `apps.list`, so disk assembly never scans
stale application outputs. To use locked
inputs without touching developer trees, create a separate OnyxOS checkout and
run `make deps` there.

Run resolver regressions with
`PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s scripts/qa -p 'test_*.py'`.

## ABI registry transition

Older component selections may predate the canonical syscall registry. Build
scripts report this legacy case explicitly. When the selected kernel contains
`scripts/generate-syscalls.py`, both image builders require its `--check` against
the resolved shell and compiler snapshots. A mismatch fails the build. Commit
and select coordinated kernel/shell/compiler revisions when updating the lock;
do not copy generated constants from a different kernel into an older release.
